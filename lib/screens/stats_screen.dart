import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../models/game_stats.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  GameStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await StorageService.loadStats();
    setState(() => _stats = s);
  }

  String _fmtDuration(int seconds) {
    if (seconds == 0) return '--';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtPercent(double v) => '${(v * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    if (_stats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final stats = _stats!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOverviewCard(stats),
          const SizedBox(height: 16),
          Text('各难度统计',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...Difficulty.values.map((d) => _buildDiffCard(stats, d)),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(GameStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('总览',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatTile(
                    label: '已玩', value: '${stats.totalGamesPlayed}'),
                _StatTile(
                    label: '胜利', value: '${stats.totalGamesWon}'),
                _StatTile(
                    label: '胜率', value: _fmtPercent(stats.winRate)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatTile(
                    label: '总用时',
                    value: _fmtDuration(stats.totalTimeSeconds)),
                _StatTile(
                    label: '当前连胜',
                    value: '${stats.currentWinStreak}'),
                _StatTile(
                    label: '最佳连胜',
                    value: '${stats.bestWinStreak}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffCard(GameStats stats, Difficulty d) {
    final ds = stats.byDifficulty[d.name];
    final played = ds?.played ?? 0;
    final won = ds?.won ?? 0;
    final best = ds?.bestTimeSeconds ?? 0;
    final avg = ds?.avgTimeSeconds ?? 0;
    final rate = ds?.winRate ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(d.name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor)),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(label: '玩', value: '$played'),
                  _MiniStat(label: '胜', value: '$won'),
                  _MiniStat(label: '胜率', value: played > 0 ? _fmtPercent(rate) : '--'),
                  _MiniStat(label: '最佳', value: _fmtDuration(best)),
                  _MiniStat(label: '平均', value: _fmtDuration(avg)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor)),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      Text(label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
    ]);
  }
}
