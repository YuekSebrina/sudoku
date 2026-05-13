import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/puzzle_cache.dart';
import 'services/storage_service.dart';
import 'services/update_service.dart';
import 'theme/app_theme.dart';
import 'widgets/update_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PuzzleCache.warmUp();
  if (!kIsWeb) {
    UpdateService.instance;
  }
  runApp(const SudokuApp());
}

class SudokuApp extends StatefulWidget {
  const SudokuApp({super.key});

  @override
  State<SudokuApp> createState() => _SudokuAppState();
}

class _SudokuAppState extends State<SudokuApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _checkForUpdateOnLaunch();
    });
  }

  Future<void> _checkForUpdateOnLaunch() async {
    final info = await UpdateService.instance.checkForUpdate();
    if (!mounted || info == null) return;

    // 延迟到首帧后的下一轮事件循环，确保 root context 已挂到 Navigator 下；
    // Windows release 启动时若直接用 MaterialApp 上层 context showDialog，
    // Navigator.of(context) 会取到 null 并导致进程异常退出。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showUpdateDialog(context, info);
      }
    });
  }

  Future<void> _loadThemeMode() async {
    final mode = await StorageService.loadThemeMode();
    if (mounted) {
      setState(() => _themeMode = mode);
    }
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    await StorageService.saveThemeMode(mode);
    if (mounted) {
      setState(() => _themeMode = mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '数独',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: HomeScreen(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}
