import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_stats.dart';

class StorageService {
  static const _keySavedGame = 'saved_game';
  static const _keyStats = 'game_stats';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // --- Saved Game ---

  static Future<void> saveGame(Map<String, dynamic> data) async {
    final prefs = await _prefs;
    await prefs.setString(_keySavedGame, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadGame() async {
    final prefs = await _prefs;
    final s = prefs.getString(_keySavedGame);
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  static Future<void> clearGame() async {
    final prefs = await _prefs;
    await prefs.remove(_keySavedGame);
  }

  // --- Stats ---

  static Future<GameStats> loadStats() async {
    final prefs = await _prefs;
    final s = prefs.getString(_keyStats);
    if (s == null) return GameStats();
    return GameStats.fromJsonString(s);
  }

  static Future<void> saveStats(GameStats stats) async {
    final prefs = await _prefs;
    await prefs.setString(_keyStats, stats.toJsonString());
  }

  static Future<void> recordWin(String diffName, Duration elapsed) async {
    final stats = await loadStats();
    stats.recordWin(diffName, elapsed);
    await saveStats(stats);
  }

  static Future<void> recordLoss(String diffName) async {
    final stats = await loadStats();
    stats.recordLoss(diffName);
    await saveStats(stats);
  }

  // --- Practice Progress ---

  static const _keyPracticeProgress = 'practice_progress';
  static const _keyThemeMode = 'theme_mode';

  static Future<Map<String, int>> loadPracticeProgress() async {
    final prefs = await _prefs;
    final s = prefs.getString(_keyPracticeProgress);
    if (s == null) return {};
    final data = jsonDecode(s) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, v as int));
  }

  static Future<void> savePracticeProgress(
    String techniqueId,
    int completed,
  ) async {
    final progress = await loadPracticeProgress();
    progress[techniqueId] = completed;
    final prefs = await _prefs;
    await prefs.setString(_keyPracticeProgress, jsonEncode(progress));
  }

  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await _prefs;
    final value = prefs.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await _prefs;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_keyThemeMode, value);
  }
}
