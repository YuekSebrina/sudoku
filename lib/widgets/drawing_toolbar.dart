import 'package:flutter/material.dart';

import '../models/drawing.dart';
import '../theme/app_theme.dart';

class DrawingToolbar extends StatelessWidget {
  final DrawingTool currentTool;
  final Color currentColor;
  final ValueChanged<DrawingTool> onToolChanged;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  const DrawingToolbar({
    super.key,
    required this.currentTool,
    required this.currentColor,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onUndo,
    required this.onClear,
  });

  static const _colors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFF757575),
  ];

  static const _tools = [
    (DrawingTool.pen, Icons.edit, '画笔'),
    (DrawingTool.arrow, Icons.arrow_right_alt, '箭头'),
    (DrawingTool.circle, Icons.circle_outlined, '画圆'),
    (DrawingTool.rectangle, Icons.crop_square, '矩形'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (tool, icon, tip) in _tools) ...[
            _ToolIcon(
              icon: icon,
              tooltip: tip,
              isActive: currentTool == tool,
              onTap: () => onToolChanged(
                currentTool == tool ? DrawingTool.none : tool,
              ),
            ),
          ],
          _divider(),
          for (final c in _colors)
            _ColorDot(
              color: c,
              isSelected: currentColor == c,
              onTap: () => onColorChanged(c),
            ),
          _divider(),
          _ToolIcon(
            icon: Icons.undo_rounded,
            tooltip: '撤销',
            onTap: onUndo,
          ),
          _ToolIcon(
            icon: Icons.delete_sweep_outlined,
            tooltip: '清除画布',
            onTap: onClear,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: 24,
        child: VerticalDivider(
          width: 1,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolIcon({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? AppTheme.primaryColor : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)]
              : null,
        ),
      ),
    );
  }
}
