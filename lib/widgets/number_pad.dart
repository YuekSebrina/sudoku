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
        return _NumberButton(
          number: number,
          remaining: remaining,
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
  final VoidCallback onTap;

  const _NumberButton({
    required this.number,
    required this.remaining,
    required this.onTap,
  });

  bool get _isCompleted => remaining <= 0;

  @override
  Widget build(BuildContext context) {
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
                color: _isCompleted ? Colors.grey.shade100 : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isCompleted ? Colors.grey.shade200 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _isCompleted
                          ? Colors.grey.shade300
                          : AppTheme.primaryColor,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _isCompleted
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
