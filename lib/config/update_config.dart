class UpdateConfig {
  const UpdateConfig._();

  // 功能总开关：线上需要快速回滚时改为 false 即可禁用更新链路。
  static const bool updateEnabled = true;
  static const String serverScheme = 'http';
  static const String serverHost = '121.43.81.198';
  static const String apiPath = '/api/version';
  static const int checkIntervalMs = 24 * 60 * 60 * 1000;
  static const int httpTimeoutSeconds = 10;
  static const String currentVersion = '1.0.0';
}
