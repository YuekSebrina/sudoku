import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/models/update_info.dart';

void main() {
  group('UpdateInfo', () {
    test('fromJson parses full update response with snake_case fields', () {
      final info = UpdateInfo.fromJson({
        'has_update': true,
        'latest_version': '1.1.0',
        'build_number': 2,
        'download_url': 'http://121.43.81.198/releases/sudoku-1.1.0.dmg',
        'file_size': 52428800,
        'file_hash': 'sha256:abc123',
        'changelog': '- 修复 bug',
        'force_update': true,
        'min_supported_version': '1.0.0',
        'release_date': '2026-05-15T10:00:00Z',
      });

      expect(info.hasUpdate, isTrue);
      expect(info.latestVersion, '1.1.0');
      expect(info.buildNumber, 2);
      expect(info.downloadUrl, contains('.dmg'));
      expect(info.fileSize, 52428800);
      expect(info.fileHash, 'sha256:abc123');
      expect(info.changelog, '- 修复 bug');
      expect(info.forceUpdate, isTrue);
      expect(info.minSupportedVersion, '1.0.0');
      expect(info.releaseDate, '2026-05-15T10:00:00Z');
    });

    test('fromJson uses safe defaults for no-update response', () {
      final info = UpdateInfo.fromJson({
        'has_update': false,
        'latest_version': '1.0.0',
      });

      expect(info.hasUpdate, isFalse);
      expect(info.latestVersion, '1.0.0');
      expect(info.buildNumber, 0);
      expect(info.downloadUrl, isEmpty);
      expect(info.fileSize, 0);
      expect(info.fileHash, isEmpty);
      expect(info.changelog, isEmpty);
      expect(info.forceUpdate, isFalse);
      expect(info.minSupportedVersion, isEmpty);
      expect(info.releaseDate, isEmpty);
    });

    test('toJson emits API-compatible snake_case fields', () {
      final info = UpdateInfo(
        hasUpdate: true,
        latestVersion: '1.2.0',
        buildNumber: 3,
        downloadUrl: 'https://example.com/sudoku.exe',
        fileSize: 100,
        fileHash: 'sha256:def456',
        changelog: '更新内容',
        forceUpdate: false,
        minSupportedVersion: '1.0.0',
        releaseDate: '2026-05-15T10:00:00Z',
      );

      expect(info.toJson(), {
        'has_update': true,
        'latest_version': '1.2.0',
        'build_number': 3,
        'download_url': 'https://example.com/sudoku.exe',
        'file_size': 100,
        'file_hash': 'sha256:def456',
        'changelog': '更新内容',
        'force_update': false,
        'min_supported_version': '1.0.0',
        'release_date': '2026-05-15T10:00:00Z',
      });
    });

    test('compareVersions orders semantic versions numerically', () {
      expect(UpdateInfo.compareVersions('1.10.0', '1.2.9'), greaterThan(0));
      expect(UpdateInfo.compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(UpdateInfo.compareVersions('2.0', '2.0.0'), 0);
    });
  });
}
