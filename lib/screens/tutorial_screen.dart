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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: categories.length,
      itemBuilder: (context, catIdx) {
        final cat = categories[catIdx];
        final items = grouped[cat] ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        final catColor = _categoryColor(cat);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(cat.icon, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 8),
                Text(
                  cat.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: catColor),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${items.length} 个技巧',
                    style: TextStyle(
                        fontSize: 11,
                        color: catColor,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ]),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int crossAxisCount;
                if (width < 360) {
                  crossAxisCount = 2;
                } else if (width < 560) {
                  crossAxisCount = 3;
                } else {
                  crossAxisCount = 4;
                }
                const spacing = 8.0;
                final itemWidth =
                    (width - spacing * (crossAxisCount - 1)) / crossAxisCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: items
                      .map((item) => SizedBox(
                            width: itemWidth,
                            child: _TutorialItemCard(
                              item: item,
                              practiceCount:
                                  _practiceProgress[item.type.name] ?? 0,
                              categoryColor: catColor,
                              onReturn: _loadProgress,
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            if (catIdx < categories.length - 1) const SizedBox(height: 4),
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
  final Color categoryColor;
  final VoidCallback? onReturn;

  const _TutorialItemCard({
    required this.item,
    required this.categoryColor,
    this.practiceCount = 0,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: categoryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 3, color: categoryColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: const BorderSide(
                                color: AppTheme.primaryColor, width: 1),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  TutorialDetailScreen(step: item),
                            ),
                          ),
                          child: const Text('学习'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => TutorialPracticeScreen(
                                    techniqueType: item.type,
                                  ),
                                ),
                              )
                              .then((_) => onReturn?.call()),
                          child: Text(
                            practiceCount > 0
                                ? '练习($practiceCount)'
                                : '练习',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
