import 'package:flutter/material.dart';

import '../data/tutorials.dart';
import '../theme/app_theme.dart';

class TutorialDetailScreen extends StatelessWidget {
  final TutorialItem item;

  const TutorialDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor)),
                  const SizedBox(height: 4),
                  Text(item.subtitle,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ..._buildContentSections(item.content),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContentSections(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (trimmed.startsWith('【') && trimmed.endsWith('】')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            trimmed,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor),
          ),
        ));
      } else if (trimmed.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('  •  ',
                  style: TextStyle(
                      fontSize: 14, color: AppTheme.primaryColor)),
              Expanded(
                  child: Text(trimmed.substring(2),
                      style: const TextStyle(fontSize: 14, height: 1.6))),
            ],
          ),
        ));
      } else if (RegExp(r'^\d+\. ').hasMatch(trimmed)) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(trimmed,
              style: const TextStyle(fontSize: 14, height: 1.6)),
        ));
      } else {
        widgets.add(Text(trimmed,
            style: const TextStyle(fontSize: 14, height: 1.6)));
      }
    }
    return widgets;
  }
}
