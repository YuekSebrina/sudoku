import 'package:flutter/material.dart';

import '../config/update_config.dart';
import '../models/update_info.dart';
import '../services/update_service.dart';

class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key, required this.info, required this.onTap});

  final UpdateInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.system_update_alt_rounded),
        title: Text('发现新版本 ${info.latestVersion}'),
        subtitle: Text(info.forceUpdate ? '此版本为强制更新' : '点击查看更新内容'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !info.forceUpdate,
    builder: (_) => PopScope(
      canPop: !info.forceUpdate,
      child: UpdateDialog(info: info),
    ),
  );
}

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.info});

  final UpdateInfo info;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _error;

  Future<void> _downloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _error = null;
    });

    final path = await UpdateService.instance.downloadUpdate(
      widget.info,
      onProgress: (value) {
        if (mounted) setState(() => _progress = value);
      },
    );

    if (!mounted) return;
    if (path == null) {
      setState(() {
        _isDownloading = false;
        _error = '下载失败，请检查网络后重试。';
      });
      return;
    }

    final installed = await UpdateService.instance.installUpdate(path);
    if (!mounted) return;
    if (!installed) {
      setState(() {
        _isDownloading = false;
        _error = '安装程序启动失败，请稍后重试。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update_alt_rounded),
          const SizedBox(width: 8),
          Expanded(child: Text('发现新版本 ${info.latestVersion}')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前版本：${UpdateConfig.currentVersion} → ${info.latestVersion}'),
            if (info.releaseDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('发布日期：${info.releaseDate}'),
            ],
            if (info.fileSize > 0) ...[
              const SizedBox(height: 8),
              Text('大小：${_formatBytes(info.fileSize)}'),
            ],
            const SizedBox(height: 16),
            const Text('更新内容：', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(info.changelog.isEmpty ? '暂无更新说明。' : info.changelog),
            if (info.forceUpdate) ...[
              const SizedBox(height: 12),
              const Text(
                '此版本为强制更新，完成更新前不能关闭该提示。',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress <= 0 ? null : _progress),
              const SizedBox(height: 8),
              Text(
                '下载中 ${(_progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: _isDownloading
          ? null
          : [
              if (!info.forceUpdate)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('暂不更新'),
                ),
              FilledButton(
                onPressed: _downloadAndInstall,
                child: Text(_error == null ? '立即更新' : '重试'),
              ),
            ],
    );
  }

  String _formatBytes(int bytes) {
    const mb = 1024 * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    const kb = 1024;
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}
