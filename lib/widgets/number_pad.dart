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
    final isDark = AppTheme.isDark(context);

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
                      ? AppTheme.primaryColor.withValues(alpha: isDark ? 0.28 : 0.12)
                      : (isDark ? const Color(0xFF2A3240) : Colors.grey.shade50),
                  shape: BoxShape.circle,
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: isActive ? 10 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                  border: isActive
                      ? Border.all(color: AppTheme.primaryColor, width: 1.5)
                      : Border.all(
                          color: isDark ? const Color(0xFF4A5568) : Colors.grey.shade200,
                          width: 1,
                        ),
                ),
                child: Icon(
                  icon,
                  color: isActive
                      ? AppTheme.primaryColor
                      : (isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade600),
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppTheme.primaryColor
                      : (isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade500),
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
    final isDark = AppTheme.isDark(context);

    Color bgColor;
    Color numColor;
    Color borderColor;
    double borderWidth = 1;

    if (_isCompleted) {
      bgColor = isDark ? const Color(0xFF242B36) : Colors.grey.shade100;
      numColor = isDark ? const Color(0xFF5B6778) : Colors.grey.shade300;
      borderColor = isDark ? const Color(0xFF374151) : Colors.grey.shade200;
    } else if (isNoteActive) {
      bgColor = AppTheme.primaryColor.withValues(alpha: isDark ? 0.24 : 0.12);
      numColor = AppTheme.primaryColor;
      borderColor = AppTheme.primaryColor;
      borderWidth = 1.5;
    } else if (isNoteDimmed) {
      bgColor = isDark ? const Color(0xFF242B36) : Colors.grey.shade50;
      numColor = isDark ? const Color(0xFF5B6778) : Colors.grey.shade300;
      borderColor = isDark ? const Color(0xFF374151) : Colors.grey.shade200;
    } else {
      bgColor = isDark ? const Color(0xFF2A3240) : Colors.white;
      numColor = isDark ? const Color(0xFF9EC1FF) : AppTheme.primaryColor;
      borderColor = isDark ? const Color(0xFF4A5568) : Colors.grey.shade300;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isCompleted ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: isNoteActive ? 14 : 8,
                          offset: const Offset(0, 4),
                        ),
                        if (!_isCompleted)
                          BoxShadow(
                            color: (isNoteActive
                                    ? AppTheme.primaryColor
                                    : Colors.white)
                                .withValues(alpha: isNoteActive ? 0.12 : 0.04),
                            blurRadius: isNoteActive ? 10 : 4,
                            spreadRadius: isNoteActive ? 0.5 : 0,
                          ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: numColor,
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _isCompleted || isNoteDimmed
                          ? (isDark ? const Color(0xFF5B6778) : Colors.grey.shade300)
                          : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade400),
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
