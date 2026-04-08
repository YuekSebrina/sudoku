import 'dart:convert';

class DifficultyStats {
  int played;
  int won;
  int bestTimeSeconds;
  int totalTimeSeconds;

  DifficultyStats({
    this.played = 0,
    this.won = 0,
    this.bestTimeSeconds = 0,
    this.totalTimeSeconds = 0,
  });

  double get winRate => played > 0 ? won / played : 0;
  int get avgTimeSeconds => won > 0 ? totalTimeSeconds ~/ won : 0;

  Map<String, dynamic> toJson() => {
        'played': played,
        'won': won,
        'bestTimeSeconds': bestTimeSeconds,
        'totalTimeSeconds': totalTimeSeconds,
      };

  factory DifficultyStats.fromJson(Map<String, dynamic> json) =>
      DifficultyStats(
        played: json['played'] ?? 0,
        won: json['won'] ?? 0,
        bestTimeSeconds: json['bestTimeSeconds'] ?? 0,
        totalTimeSeconds: json['totalTimeSeconds'] ?? 0,
      );
}

class GameStats {
  int totalGamesPlayed;
  int totalGamesWon;
  int totalTimeSeconds;
  int currentWinStreak;
  int bestWinStreak;
  Map<String, DifficultyStats> byDifficulty;

  GameStats({
    this.totalGamesPlayed = 0,
    this.totalGamesWon = 0,
    this.totalTimeSeconds = 0,
    this.currentWinStreak = 0,
    this.bestWinStreak = 0,
    Map<String, DifficultyStats>? byDifficulty,
  }) : byDifficulty = byDifficulty ?? {};

  double get winRate => totalGamesPlayed > 0 ? totalGamesWon / totalGamesPlayed : 0;

  DifficultyStats getFor(String diffName) =>
      byDifficulty.putIfAbsent(diffName, () => DifficultyStats());

  void recordWin(String diffName, Duration elapsed) {
    totalGamesPlayed++;
    totalGamesWon++;
    totalTimeSeconds += elapsed.inSeconds;
    currentWinStreak++;
    if (currentWinStreak > bestWinStreak) bestWinStreak = currentWinStreak;

    final ds = getFor(diffName);
    ds.played++;
    ds.won++;
    ds.totalTimeSeconds += elapsed.inSeconds;
    if (ds.bestTimeSeconds == 0 || elapsed.inSeconds < ds.bestTimeSeconds) {
      ds.bestTimeSeconds = elapsed.inSeconds;
    }
  }

  void recordLoss(String diffName) {
    totalGamesPlayed++;
    currentWinStreak = 0;

    final ds = getFor(diffName);
    ds.played++;
  }

  String toJsonString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
        'totalGamesPlayed': totalGamesPlayed,
        'totalGamesWon': totalGamesWon,
        'totalTimeSeconds': totalTimeSeconds,
        'currentWinStreak': currentWinStreak,
        'bestWinStreak': bestWinStreak,
        'byDifficulty': byDifficulty.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory GameStats.fromJsonString(String s) =>
      GameStats.fromJson(jsonDecode(s));

  factory GameStats.fromJson(Map<String, dynamic> json) => GameStats(
        totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
        totalGamesWon: json['totalGamesWon'] ?? 0,
        totalTimeSeconds: json['totalTimeSeconds'] ?? 0,
        currentWinStreak: json['currentWinStreak'] ?? 0,
        bestWinStreak: json['bestWinStreak'] ?? 0,
        byDifficulty: (json['byDifficulty'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, DifficultyStats.fromJson(v)),
            ) ??
            {},
      );
}
