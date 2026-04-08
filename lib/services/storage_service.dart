import 'dart:convert';

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
}
