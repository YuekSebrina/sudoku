import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/models/update_info.dart';
import 'package:sudoku/services/update_service.dart';

void main() {
  group('UpdateService', () {
    test('buildApiUri uses v2 API contract', () {
      final uri = UpdateService.buildApiUri(
        platform: 'macos',
        currentVersion: '1.0.0',
      );

      expect(
        uri.toString(),
        'http://121.43.81.198/api/version?platform=macos&current_version=1.0.0',
      );
    });

    test(
      'checkForUpdate parses update response from injected HTTP client',
      () async {
        final service = UpdateService(
          platformProvider: () => 'macos',
          promptStore: InMemoryPromptStore(),
          httpGet: (uri) async => {
            'has_update': true,
            'latest_version': '1.1.0',
            'download_url': 'http://example.com/sudoku.dmg',
            'force_update': false,
          },
        );

        final info = await service.checkForUpdate(manual: true);

        expect(info, isNotNull);
        expect(info!.hasUpdate, isTrue);
        expect(info.latestVersion, '1.1.0');
        expect(info.downloadUrl, endsWith('.dmg'));
      },
    );

    test('checkForUpdate returns null when disabled', () async {
      var called = false;
      final service = UpdateService(
        updateEnabled: false,
        platformProvider: () => 'macos',
        httpGet: (uri) async {
          called = true;
          return {'has_update': true, 'latest_version': '1.1.0'};
        },
      );

      final info = await service.checkForUpdate(manual: true);

      expect(info, isNull);
      expect(called, isFalse);
    });

    test('checkForUpdate skips unsupported platforms', () async {
      var called = false;
      final service = UpdateService(
        platformProvider: () => 'linux',
        httpGet: (uri) async {
          called = true;
          return {'has_update': true, 'latest_version': '1.1.0'};
        },
      );

      final info = await service.checkForUpdate(manual: true);

      expect(info, isNull);
      expect(called, isFalse);
    });

    test(
      'checkForUpdate suppresses same optional version within 24 hours',
      () async {
        final now = DateTime(2026, 5, 13, 9);
        final store = InMemoryPromptStore(
          promptedVersion: '1.1.0',
          promptedAtMs: now
              .subtract(const Duration(hours: 2))
              .millisecondsSinceEpoch,
        );
        final service = UpdateService(
          platformProvider: () => 'macos',
          nowProvider: () => now,
          promptStore: store,
          httpGet: (uri) async => {
            'has_update': true,
            'latest_version': '1.1.0',
            'download_url': 'http://example.com/sudoku.dmg',
            'force_update': false,
          },
        );

        final info = await service.checkForUpdate();

        expect(info, isNull);
      },
    );

    test(
      'checkForUpdate does not suppress force update within 24 hours',
      () async {
        final now = DateTime(2026, 5, 13, 9);
        final store = InMemoryPromptStore(
          promptedVersion: '1.1.0',
          promptedAtMs: now
              .subtract(const Duration(hours: 2))
              .millisecondsSinceEpoch,
        );
        final service = UpdateService(
          platformProvider: () => 'macos',
          nowProvider: () => now,
          promptStore: store,
          httpGet: (uri) async => {
            'has_update': true,
            'latest_version': '1.1.0',
            'download_url': 'http://example.com/sudoku.dmg',
            'force_update': true,
          },
        );

        final info = await service.checkForUpdate();

        expect(info, isNotNull);
        expect(info!.forceUpdate, isTrue);
      },
    );

    test('downloadUpdate writes response body and reports progress', () async {
      final downloadUrl = 'http://127.0.0.1/sudoku.dmg';

      final tempDir = await Directory.systemTemp.createTemp(
        'sudoku_update_test_',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final service = UpdateService(
        platformProvider: () => 'macos',
        tempDirectoryProvider: () => tempDir,
        httpByteDownloader: (uri, targetFile, onProgress) async {
          await targetFile.writeAsString('installer');
          onProgress?.call(1.0);
          return targetFile.path;
        },
      );
      final progress = <double>[];

      final path = await service.downloadUpdate(
        UpdateInfo(
          hasUpdate: true,
          latestVersion: '1.1.0',
          downloadUrl: downloadUrl,
        ),
        onProgress: progress.add,
      );

      expect(path, isNotNull);
      expect(File(path!).readAsStringSync(), 'installer');
      expect(path, endsWith('.dmg'));
      expect(progress.last, 1.0);
    });

    test(
      'downloadUpdate preserves zip extension from Windows download URL',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'sudoku_update_windows_zip_test_',
        );
        addTearDown(() => tempDir.delete(recursive: true));
        final service = UpdateService(
          platformProvider: () => 'windows',
          tempDirectoryProvider: () => tempDir,
          httpByteDownloader: (uri, targetFile, onProgress) async {
            await targetFile.writeAsString('zip-bytes');
            return targetFile.path;
          },
        );

        final path = await service.downloadUpdate(
          const UpdateInfo(
            hasUpdate: true,
            latestVersion: '1.1.0',
            downloadUrl: 'http://127.0.0.1/releases/sudoku-windows-1.1.0.zip',
          ),
        );

        expect(path, isNotNull);
        expect(path, endsWith('.zip'));
        expect(File(path!).readAsStringSync(), 'zip-bytes');
      },
    );

    test('installUpdate opens Windows zip package with explorer', () async {
      final commands = <List<String>>[];
      final service = UpdateService(
        platformProvider: () => 'windows',
        processRunner: (executable, arguments) async {
          commands.add([executable, ...arguments]);
          return ProcessResult(1, 0, '', '');
        },
      );

      final ok = await service.installUpdate(
        'C:\\Temp\\sudoku-update-1.1.0.zip',
      );

      expect(ok, isTrue);
      expect(commands.single, [
        'explorer',
        'C:\\Temp\\sudoku-update-1.1.0.zip',
      ]);
    });

    test('installUpdate runs injected installer command', () async {
      final commands = <List<String>>[];
      final service = UpdateService(
        platformProvider: () => 'windows',
        processRunner: (executable, arguments) async {
          commands.add([executable, ...arguments]);
          return ProcessResult(1, 0, '', '');
        },
      );

      final ok = await service.installUpdate('C:\\Temp\\sudoku.exe');

      expect(ok, isTrue);
      expect(commands.single, [
        'cmd',
        '/c',
        'start',
        '',
        'C:\\Temp\\sudoku.exe',
      ]);
    });
  });
}

class InMemoryPromptStore implements UpdatePromptStore {
  InMemoryPromptStore({this.promptedVersion, this.promptedAtMs});

  String? promptedVersion;
  int? promptedAtMs;

  @override
  Future<String?> getLastPromptedVersion() async => promptedVersion;

  @override
  Future<int?> getLastPromptedAtMs() async => promptedAtMs;

  @override
  Future<void> savePromptedVersion(String version, DateTime promptedAt) async {
    promptedVersion = version;
    promptedAtMs = promptedAt.millisecondsSinceEpoch;
  }
}
