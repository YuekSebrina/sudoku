import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/puzzle_cache.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PuzzleCache.warmUp();
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
