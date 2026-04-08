import 'package:flutter/material.dart';

import '../data/tutorial_boards.dart';
import '../models/technique.dart';
import '../models/tutorial_step.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'tutorial_detail_screen.dart';
import 'tutorial_practice_screen.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  Map<String, int> _practiceProgress = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await StorageService.loadPracticeProgress();
    if (mounted) setState(() => _practiceProgress = progress);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = tutorialsByCategory;
    final categories = TechniqueCategory.values;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, catIdx) {
        final cat = categories[catIdx];
        final items = grouped[cat] ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Text(cat.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  cat.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _categoryColor(cat)),
                ),
                const SizedBox(width: 8),
                Text(
                  '${items.length} 个技巧',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ]),
            ),
            ...items.map((item) => _TutorialItemCard(
              item: item,
              practiceCount: _practiceProgress[item.type.name] ?? 0,
              onReturn: _loadProgress,
            )),
            if (catIdx < categories.length - 1) const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  static Color _categoryColor(TechniqueCategory cat) {
    switch (cat) {
      case TechniqueCategory.beginner:
        return AppTheme.successColor;
      case TechniqueCategory.intermediate:
        return AppTheme.primaryColor;
      case TechniqueCategory.advanced:
        return AppTheme.accentColor;
      case TechniqueCategory.expert:
        return AppTheme.errorColor;
      case TechniqueCategory.chains:
        return Colors.purple;
    }
  }
}

class _TutorialItemCard extends StatelessWidget {
  final TutorialStep item;
  final int practiceCount;
  final VoidCallback? onReturn;
  const _TutorialItemCard({
    required this.item,
    this.practiceCount = 0,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.school, size: 18),
                    label: const Text('学习'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TutorialDetailScreen(step: item),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.fitness_center, size: 18),
                    label: Text(practiceCount > 0
                        ? '练习 ($practiceCount)'
                        : '练习'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TutorialPracticeScreen(
                          techniqueType: item.type,
                        ),
                      ),
                    ).then((_) => onReturn?.call()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
