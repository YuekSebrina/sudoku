import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../models/game_stats.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';
import 'stats_screen.dart';
import 'tutorial_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

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
    if (mounted) {
      setState(() {
        _savedGame = saved;
        _stats = stats;
      });
    }
  }

  void _startGame(BuildContext context, Difficulty difficulty) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => GameScreen(
                  difficulty: difficulty,
                  themeMode: widget.themeMode,
                  onThemeModeChanged: widget.onThemeModeChanged,
                )))
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
            builder: (_) => GameScreen(
                  difficulty: difficulty,
                  savedGame: _savedGame,
                  themeMode: widget.themeMode,
                  onThemeModeChanged: widget.onThemeModeChanged,
                )))
        .then((_) => _refresh());
  }

  void _showDifficultyPicker(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.78;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择难度',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ...Difficulty.values.map(
                        (difficulty) => _buildDifficultyOption(ctx, difficulty),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(BuildContext context, Difficulty difficulty) {
    final ds = _stats?.byDifficulty[difficulty.name];
    final bestTime = ds?.bestTimeSeconds ?? 0;
    final played = ds?.played ?? 0;
    final won = ds?.won ?? 0;
    final icon = _difficultyIcon(difficulty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          onTap: () {
            Navigator.of(context).pop();
            _startGame(this.context, difficulty);
          },
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          title: Text(
            difficulty.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            played > 0
                ? '胜 $won/$played · 最佳 ${_fmtTime(bestTime)}'
                : '${difficulty.clues} 个提示数',
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  IconData _difficultyIcon(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Icons.sentiment_satisfied_alt_rounded;
      case Difficulty.medium:
        return Icons.emoji_objects_outlined;
      case Difficulty.hard:
        return Icons.fitness_center_rounded;
      case Difficulty.expert:
        return Icons.psychology_alt_outlined;
      case Difficulty.extreme:
        return Icons.local_fire_department_outlined;
      case Difficulty.abyss:
        return Icons.dark_mode_rounded;
    }
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
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: '显示模式',
                  onPressed: () => _showThemeModeDialog(context),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.grid_on, size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: 12),
              Text('数独',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
              const SizedBox(height: 4),
              Text('经典数字逻辑游戏',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
              const SizedBox(height: 56),
              _buildActionBasket(
                context,
                title: '继续游戏',
                subtitle: _savedGame != null
                    ? '${_savedGame!['difficulty']} · ${_fmtTime(_savedGame!['elapsed'] as int? ?? 0)} · 错误 ${_savedGame!['mistakes'] as int? ?? 0}/3'
                    : '暂无未完成的对局',
                icon: Icons.history_rounded,
                onTap: _savedGame != null ? () => _continueGame(context) : null,
                accentColor: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              _buildActionBasket(
                context,
                title: '新游戏',
                subtitle: '点击后选择难度并开始新的一局',
                icon: Icons.add_circle_outline_rounded,
                onTap: () => _showDifficultyPicker(context),
                accentColor: AppTheme.accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('显示模式'),
        content: SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              label: Text('亮色'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              label: Text('暗色'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              label: Text('系统'),
              icon: Icon(Icons.brightness_auto_outlined),
            ),
          ],
          selected: {widget.themeMode},
          onSelectionChanged: (selection) {
            widget.onThemeModeChanged(selection.first);
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBasket(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
    required Color accentColor,
  }) {
    final disabled = onTap == null;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: disabled
                  ? [
                      Colors.grey.shade300,
                      Colors.grey.shade200,
                    ]
                  : [
                      accentColor.withValues(alpha: 0.18),
                      accentColor.withValues(alpha: 0.06),
                    ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: disabled
                      ? Colors.white.withValues(alpha: 0.55)
                      : accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: disabled ? Colors.grey.shade500 : accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: disabled ? Colors.grey.shade700 : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: disabled ? Colors.grey.shade600 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: disabled ? Colors.grey.shade500 : accentColor,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
