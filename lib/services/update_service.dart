import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/update_config.dart';
import '../models/update_info.dart';

typedef UpdateHttpGet = Future<Map<String, dynamic>?> Function(Uri uri);
typedef UpdatePlatformProvider = String Function();
typedef UpdateTempDirectoryProvider = Directory Function();
typedef UpdateProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);
typedef UpdateHttpByteDownloader =
    Future<String?> Function(
      Uri uri,
      File targetFile,
      ValueChanged<double>? onProgress,
    );
typedef UpdateNowProvider = DateTime Function();

abstract class UpdatePromptStore {
  Future<String?> getLastPromptedVersion();
  Future<int?> getLastPromptedAtMs();
  Future<void> savePromptedVersion(String version, DateTime promptedAt);
}

class SharedPreferencesUpdatePromptStore implements UpdatePromptStore {
  static const _keyLastPromptedVersion = 'update_last_prompted_version';
  static const _keyLastPromptedAtMs = 'update_last_prompted_at_ms';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<String?> getLastPromptedVersion() async {
    return (await _prefs).getString(_keyLastPromptedVersion);
  }

  @override
  Future<int?> getLastPromptedAtMs() async {
    return (await _prefs).getInt(_keyLastPromptedAtMs);
  }

  @override
  Future<void> savePromptedVersion(String version, DateTime promptedAt) async {
    final prefs = await _prefs;
    await prefs.setString(_keyLastPromptedVersion, version);
    await prefs.setInt(_keyLastPromptedAtMs, promptedAt.millisecondsSinceEpoch);
  }
}

class UpdateService {
  UpdateService({
    bool? updateEnabled,
    UpdatePlatformProvider? platformProvider,
    UpdateHttpGet? httpGet,
    UpdateTempDirectoryProvider? tempDirectoryProvider,
    UpdateProcessRunner? processRunner,
    UpdateHttpByteDownloader? httpByteDownloader,
    UpdateNowProvider? nowProvider,
    UpdatePromptStore? promptStore,
  }) : _updateEnabled = updateEnabled ?? UpdateConfig.updateEnabled,
       _platformProvider = platformProvider ?? _defaultPlatform,
       _httpGet = httpGet ?? _defaultHttpGet,
       _tempDirectoryProvider =
           tempDirectoryProvider ?? (() => Directory.systemTemp),
       _processRunner =
           processRunner ??
           ((executable, arguments) => Process.run(executable, arguments)),
       _httpByteDownloader = httpByteDownloader ?? _defaultHttpByteDownloader,
       _nowProvider = nowProvider ?? DateTime.now,
       _promptStore = promptStore ?? SharedPreferencesUpdatePromptStore();

  static final UpdateService instance = UpdateService();

  final bool _updateEnabled;
  final UpdatePlatformProvider _platformProvider;
  final UpdateHttpGet _httpGet;
  final UpdateTempDirectoryProvider _tempDirectoryProvider;
  final UpdateProcessRunner _processRunner;
  final UpdateHttpByteDownloader _httpByteDownloader;
  final UpdateNowProvider _nowProvider;
  final UpdatePromptStore _promptStore;

  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  Future<UpdateInfo?> checkForUpdate({bool manual = false}) async {
    if (_isChecking || !_updateEnabled || kIsWeb) return null;
    final platform = _platformProvider();
    if (!_isSupportedPlatform(platform)) return null;

    _isChecking = true;
    try {
      final uri = buildApiUri(platform: platform);
      final response = await _httpGet(uri);
      if (response == null) return null;

      final info = UpdateInfo.fromJson(response);
      if (!info.hasUpdate) return null;
      if (!manual && !info.forceUpdate && await _wasRecentlyPrompted(info)) {
        return null;
      }

      await _promptStore.savePromptedVersion(
        info.latestVersion,
        _nowProvider(),
      );
      return info;
    } catch (error) {
      // 更新检查不能影响主应用启动；仅 debug 输出便于开发定位。
      debugPrint('Update check failed: $error');
      return null;
    } finally {
      _isChecking = false;
    }
  }

  Future<String?> downloadUpdate(
    UpdateInfo info, {
    ValueChanged<double>? onProgress,
  }) async {
    if (_isDownloading || info.downloadUrl.isEmpty) return null;
    _isDownloading = true;
    _downloadProgress = 0.0;

    final platform = _platformProvider();
    final downloadUri = Uri.parse(info.downloadUrl);
    final extension = _extensionFromDownloadUri(
      downloadUri,
      platform: platform,
    );
    final file = File(
      '${_tempDirectoryProvider().path}${Platform.pathSeparator}'
      'sudoku-update-${info.latestVersion}$extension',
    );

    try {
      final path = await _httpByteDownloader(downloadUri, file, (value) {
        _downloadProgress = value.clamp(0.0, 1.0);
        onProgress?.call(_downloadProgress);
      });
      if (path == null) return null;
      _downloadProgress = 1.0;
      onProgress?.call(_downloadProgress);
      return path;
    } catch (error) {
      if (await file.exists()) {
        await file.delete();
      }
      debugPrint('Update download failed: $error');
      return null;
    } finally {
      _isDownloading = false;
    }
  }

  Future<bool> installUpdate(String localPath) async {
    final platform = _platformProvider();
    try {
      final ProcessResult result;
      if (platform == 'macos') {
        result = await _processRunner('open', [localPath]);
      } else if (platform == 'windows') {
        final extension = _extensionFromPath(localPath).toLowerCase();
        if (extension == '.zip') {
          // ZIP 更新包不是可执行安装器，打开资源管理器让用户查看/解压。
          result = await _processRunner('explorer', [localPath]);
        } else {
          result = await _processRunner('cmd', ['/c', 'start', '', localPath]);
        }
      } else {
        return false;
      }
      return result.exitCode == 0;
    } catch (error) {
      debugPrint('Update install failed: $error');
      return false;
    }
  }

  static Uri buildApiUri({
    required String platform,
    String currentVersion = UpdateConfig.currentVersion,
  }) {
    return Uri(
      scheme: UpdateConfig.serverScheme,
      host: UpdateConfig.serverHost,
      path: UpdateConfig.apiPath,
      queryParameters: {
        'platform': platform,
        'current_version': currentVersion,
      },
    );
  }

  static bool _isSupportedPlatform(String platform) {
    return platform == 'macos' || platform == 'windows';
  }

  static String _extensionFromDownloadUri(Uri uri, {required String platform}) {
    final extension = _extensionFromPath(uri.path).toLowerCase();
    if (extension.isNotEmpty) return extension;

    // 兼容极少数无扩展下载地址；正常路径必须优先保留服务端文件扩展名。
    if (platform == 'macos') return '.dmg';
    if (platform == 'windows') return '.exe';
    return '.bin';
  }

  static String _extensionFromPath(String path) {
    final normalizedPath = path.replaceAll('\\', '/');
    final fileName = normalizedPath.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex);
  }

  Future<bool> _wasRecentlyPrompted(UpdateInfo info) async {
    final lastVersion = await _promptStore.getLastPromptedVersion();
    final lastAtMs = await _promptStore.getLastPromptedAtMs();
    if (lastVersion != info.latestVersion || lastAtMs == null) return false;

    final lastAt = DateTime.fromMillisecondsSinceEpoch(lastAtMs);
    return _nowProvider().difference(lastAt).inMilliseconds <
        UpdateConfig.checkIntervalMs;
  }

  static String _defaultPlatform() {
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    return Platform.operatingSystem;
  }

  static Future<String?> _defaultHttpByteDownloader(
    Uri uri,
    File targetFile,
    ValueChanged<double>? onProgress,
  ) async {
    final request = await HttpClient()
        .getUrl(uri)
        .timeout(const Duration(seconds: UpdateConfig.httpTimeoutSeconds));
    final response = await request.close().timeout(
      const Duration(seconds: UpdateConfig.httpTimeoutSeconds),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('download failed: HTTP ${response.statusCode}');
    }

    final sink = targetFile.openWrite();
    var received = 0;
    final total = response.contentLength;
    try {
      await for (final chunk in response) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) {
          onProgress?.call((received / total).clamp(0.0, 1.0));
        }
      }
    } finally {
      await sink.close();
    }
    onProgress?.call(1.0);
    return targetFile.path;
  }

  static Future<Map<String, dynamic>?> _defaultHttpGet(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(
        seconds: UpdateConfig.httpTimeoutSeconds,
      );
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: UpdateConfig.httpTimeoutSeconds));
      final response = await request.close().timeout(
        const Duration(seconds: UpdateConfig.httpTimeoutSeconds),
      );
      if (response.statusCode != HttpStatus.ok) return null;

      final body = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } finally {
      client.close(force: true);
    }
  }
}
