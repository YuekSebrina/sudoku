import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../models/game_stats.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';
import 'stats_screen.dart';
import 'tutorial_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  Map<String, dynamic>? _savedGame;
  GameStats? _stats;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final saved = await StorageService.loadGame();
    final stats = await StorageService.loadStats();
    if (mounted) setState(() { _savedGame = saved; _stats = stats; });
  }

  void _startGame(BuildContext context, Difficulty difficulty) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => GameScreen(difficulty: difficulty)))
        .then((_) => _refresh());
  }

  void _continueGame(BuildContext context) {
    if (_savedGame == null) return;
    final diffName = _savedGame!['difficulty'] as String;
    final difficulty = Difficulty.values.firstWhere(
      (d) => d.name == diffName,
      orElse: () => Difficulty.easy,
    );
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) =>
                GameScreen(difficulty: difficulty, savedGame: _savedGame)))
        .then((_) => _refresh());
  }

  String _fmtTime(int seconds) {
    if (seconds == 0) return '--';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            _buildPlayTab(context),
            const TutorialScreen(),
            const StatsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.play_circle_outline),
              selectedIcon: Icon(Icons.play_circle),
              label: '游戏'),
          NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: '教学'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: '统计'),
        ],
      ),
    );
  }

  Widget _buildPlayTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.grid_on, size: 64, color: AppTheme.primaryColor),
            const SizedBox(height: 12),
            Text('数独',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor)),
            const SizedBox(height: 4),
            Text('经典数字逻辑游戏',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            if (_savedGame != null) _buildContinueCard(context),
            if (_savedGame != null) const SizedBox(height: 16),
            ...Difficulty.values.map((d) => _buildDifficultyCard(context, d)),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueCard(BuildContext context) {
    final diffName = _savedGame!['difficulty'] as String;
    final elapsed = _savedGame!['elapsed'] as int? ?? 0;
    final mistakes = _savedGame!['mistakes'] as int? ?? 0;

    return Card(
      color: AppTheme.primaryColor,
      child: InkWell(
        onTap: () => _continueGame(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('继续解题',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      '$diffName · ${_fmtTime(elapsed)} · 错误 $mistakes/3',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(BuildContext context, Difficulty d) {
    final ds = _stats?.byDifficulty[d.name];
    final bestTime = ds?.bestTimeSeconds ?? 0;
    final played = ds?.played ?? 0;
    final won = ds?.won ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _startGame(context, d),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('${d.clues}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        played > 0
                            ? '胜 $won/$played · 最佳 ${_fmtTime(bestTime)}'
                            : '${d.clues} 个提示数',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
