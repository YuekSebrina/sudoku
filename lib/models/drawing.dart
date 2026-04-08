import 'dart:ui';

enum DrawingTool { none, pen, arrow, circle, rectangle }

class DrawingElement {
  final DrawingTool tool;
  final Color color;
  final double strokeWidth;
  final List<Offset> points;

  DrawingElement({
    required this.tool,
    required this.color,
    this.strokeWidth = 2.5,
    List<Offset>? points,
  }) : points = points ?? [];

  DrawingElement copyWith({List<Offset>? points}) {
    return DrawingElement(
      tool: tool,
      color: color,
      strokeWidth: strokeWidth,
      points: points ?? List.from(this.points),
    );
  }
}
