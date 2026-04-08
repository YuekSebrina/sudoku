import 'package:flutter/material.dart';

import '../models/technique.dart';
import '../theme/app_theme.dart';
import 'interactive_tutorial_board.dart';

/// A two-step hint overlay shown during gameplay.
///
/// Step 1: Shows the technique visualization with explanation.
/// Step 2: Applies the technique (eliminates candidates / places digit).
class HintOverlay extends StatefulWidget {
  final List<List<int>> boardValues;
  final List<List<Set<int>>> boardCandidates;
  final TechniqueResult techniqueResult;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  const HintOverlay({
    super.key,
    required this.boardValues,
    required this.boardCandidates,
    required this.techniqueResult,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  State<HintOverlay> createState() => _HintOverlayState();
}

class _HintOverlayState extends State<HintOverlay> {
  bool _showStep2 = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onDismiss,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _categoryColor(widget.techniqueResult.type.category),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.techniqueResult.type.category.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.techniqueResult.type.nameZh,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Board
              Expanded(
                child: Center(
                  child: InteractiveTutorialBoard(
                    boardValues: widget.boardValues,
                    boardCandidates: widget.boardCandidates,
                    techniqueResult: widget.techniqueResult,
                    showEliminations: _showStep2,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showStep2 ? '第二步：应用解法' : '第一步：分析',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.techniqueResult.description,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showStep2 ? widget.onApply : () {
                    setState(() => _showStep2 = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _showStep2 ? '应用此解法' : '下一步',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(TechniqueCategory category) {
    switch (category) {
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
