class UpdateInfo {
  const UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    this.buildNumber = 0,
    this.downloadUrl = '',
    this.fileSize = 0,
    this.fileHash = '',
    this.changelog = '',
    this.forceUpdate = false,
    this.minSupportedVersion = '',
    this.releaseDate = '',
  });

  final bool hasUpdate;
  final String latestVersion;
  final int buildNumber;
  final String downloadUrl;
  final int fileSize;
  final String fileHash;
  final String changelog;
  final bool forceUpdate;
  final String minSupportedVersion;
  final String releaseDate;

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      hasUpdate: json['has_update'] == true,
      latestVersion: _asString(json['latest_version']),
      buildNumber: _asInt(json['build_number']),
      downloadUrl: _asString(json['download_url']),
      fileSize: _asInt(json['file_size']),
      fileHash: _asString(json['file_hash']),
      changelog: _asString(json['changelog']),
      forceUpdate: json['force_update'] == true,
      minSupportedVersion: _asString(json['min_supported_version']),
      releaseDate: _asString(json['release_date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'has_update': hasUpdate,
    'latest_version': latestVersion,
    'build_number': buildNumber,
    'download_url': downloadUrl,
    'file_size': fileSize,
    'file_hash': fileHash,
    'changelog': changelog,
    'force_update': forceUpdate,
    'min_supported_version': minSupportedVersion,
    'release_date': releaseDate,
  };

  static int compareVersions(String v1, String v2) {
    final left = _versionParts(v1);
    final right = _versionParts(v2);
    final maxLength = left.length > right.length ? left.length : right.length;

    for (var i = 0; i < maxLength; i++) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      if (l != r) return l.compareTo(r);
    }
    return 0;
  }

  static List<int> _versionParts(String version) {
    final normalized = version.split('+').first.split('-').first;
    return normalized
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList(growable: false);
  }

  static String _asString(Object? value) => value?.toString() ?? '';

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
