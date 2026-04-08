import 'package:flutter/material.dart';

import '../data/tutorials.dart';
import '../theme/app_theme.dart';
import 'tutorial_detail_screen.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tutorials.length,
      itemBuilder: (context, catIdx) {
        final cat = tutorials[catIdx];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Text(cat.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(cat.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
              ]),
            ),
            ...cat.items.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: Text(item.subtitle,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppTheme.primaryColor),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => TutorialDetailScreen(item: item)),
                    ),
                  ),
                )),
            if (catIdx < tutorials.length - 1) const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
