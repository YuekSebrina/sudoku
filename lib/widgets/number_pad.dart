import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NumberPad extends StatelessWidget {
  final ValueChanged<int> onNumberTap;
  final VoidCallback onDelete;
  final VoidCallback onNotesToggle;
  final VoidCallback onHint;
  final VoidCallback onUndo;
  final VoidCallback? onAutoNotes;
  final bool isNotesMode;
  final Map<int, int> remainingCounts;
  final Set<int> activeNotes;

  const NumberPad({
    super.key,
    required this.onNumberTap,
    required this.onDelete,
    required this.onNotesToggle,
    required this.onHint,
    required this.onUndo,
    this.onAutoNotes,
    required this.isNotesMode,
    this.remainingCounts = const {},
    this.activeNotes = const {},
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        children: [
          _buildNumberRow(context),
          const SizedBox(height: 14),
          _buildToolRow(context),
        ],
      ),
    );
  }

  Widget _buildToolRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ToolButton(
          icon: Icons.undo_rounded,
          label: '撤销',
          onTap: onUndo,
        ),
        _ToolButton(
          icon: Icons.backspace_outlined,
          label: '擦除',
          onTap: onDelete,
        ),
        _ToolButton(
          icon: Icons.edit_outlined,
          label: '笔记',
          onTap: onNotesToggle,
          isActive: isNotesMode,
        ),
        _ToolButton(
          icon: Icons.auto_fix_high_rounded,
          label: '候选数',
          onTap: onAutoNotes ?? () {},
        ),
        _ToolButton(
          icon: Icons.lightbulb_outline_rounded,
          label: '提示',
          onTap: onHint,
        ),
      ],
    );
  }

  Widget _buildNumberRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(9, (index) {
        final number = index + 1;
        final remaining = remainingCounts[number] ?? 9;
        final isNoteActive = isNotesMode && activeNotes.contains(number);
        final isNoteDimmed = isNotesMode && !activeNotes.contains(number);
        return _NumberButton(
          number: number,
          remaining: remaining,
          isNoteActive: isNoteActive,
          isNoteDimmed: isNoteDimmed,
          onTap: () => onNumberTap(number),
        );
      }),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryColor.withValues(alpha: 0.12)
                      : Colors.grey.shade50,
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(color: AppTheme.primaryColor, width: 1.5)
                      : Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Icon(
                  icon,
                  color: isActive ? AppTheme.primaryColor : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppTheme.primaryColor : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final int number;
  final int remaining;
  final bool isNoteActive;
  final bool isNoteDimmed;
  final VoidCallback onTap;

  const _NumberButton({
    required this.number,
    required this.remaining,
    this.isNoteActive = false,
    this.isNoteDimmed = false,
    required this.onTap,
  });

  bool get _isCompleted => remaining <= 0;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color numColor;
    Color borderColor;
    double borderWidth = 1;

    if (_isCompleted) {
      bgColor = Colors.grey.shade100;
      numColor = Colors.grey.shade300;
      borderColor = Colors.grey.shade200;
    } else if (isNoteActive) {
      bgColor = AppTheme.primaryColor.withValues(alpha: 0.12);
      numColor = AppTheme.primaryColor;
      borderColor = AppTheme.primaryColor;
      borderWidth = 1.5;
    } else if (isNoteDimmed) {
      bgColor = Colors.grey.shade50;
      numColor = Colors.grey.shade300;
      borderColor = Colors.grey.shade200;
    } else {
      bgColor = Colors.white;
      numColor = AppTheme.primaryColor;
      borderColor = Colors.grey.shade300;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isCompleted ? null : onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: numColor,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _isCompleted || isNoteDimmed
                          ? Colors.grey.shade300
                          : Colors.grey.shade400,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
