import 'dart:math';

import 'package:flutter/material.dart';

import '../models/drawing.dart';

class DrawingOverlay extends StatefulWidget {
  final bool isActive;
  final DrawingTool currentTool;
  final Color currentColor;
  final List<DrawingElement> elements;
  final ValueChanged<List<DrawingElement>> onElementsChanged;

  const DrawingOverlay({
    super.key,
    required this.isActive,
    required this.currentTool,
    required this.currentColor,
    required this.elements,
    required this.onElementsChanged,
  });

  @override
  State<DrawingOverlay> createState() => _DrawingOverlayState();
}

class _DrawingOverlayState extends State<DrawingOverlay> {
  DrawingElement? _current;

  void _onPanStart(DragStartDetails details) {
    if (!widget.isActive || widget.currentTool == DrawingTool.none) return;
    setState(() {
      _current = DrawingElement(
        tool: widget.currentTool,
        color: widget.currentColor,
        points: [details.localPosition],
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_current == null) return;
    setState(() {
      if (_current!.tool == DrawingTool.pen) {
        _current!.points.add(details.localPosition);
      } else {
        if (_current!.points.length > 1) {
          _current!.points.last = details.localPosition;
        } else {
          _current!.points.add(details.localPosition);
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_current == null) return;
    final updated = [...widget.elements, _current!.copyWith()];
    widget.onElementsChanged(updated);
    setState(() => _current = null);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.isActive
          ? HitTestBehavior.opaque
          : HitTestBehavior.translucent,
      onPanStart: widget.isActive ? _onPanStart : null,
      onPanUpdate: widget.isActive ? _onPanUpdate : null,
      onPanEnd: widget.isActive ? _onPanEnd : null,
      child: IgnorePointer(
        ignoring: !widget.isActive,
        child: CustomPaint(
          painter: _DrawingPainter(
            elements: widget.elements,
            current: _current,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingElement> elements;
  final DrawingElement? current;

  _DrawingPainter({required this.elements, this.current});

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in elements) {
      _drawElement(canvas, e);
    }
    if (current != null) {
      _drawElement(canvas, current!);
    }
  }

  void _drawElement(Canvas canvas, DrawingElement e) {
    final paint = Paint()
      ..color = e.color
      ..strokeWidth = e.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (e.points.length < 2) return;

    switch (e.tool) {
      case DrawingTool.pen:
        final path = Path()..moveTo(e.points.first.dx, e.points.first.dy);
        for (int i = 1; i < e.points.length; i++) {
          path.lineTo(e.points[i].dx, e.points[i].dy);
        }
        canvas.drawPath(path, paint);
        break;

      case DrawingTool.arrow:
        final start = e.points.first;
        final end = e.points.last;
        canvas.drawLine(start, end, paint);
        final angle = atan2(end.dy - start.dy, end.dx - start.dx);
        const arrowLen = 12.0;
        const arrowAngle = 0.5;
        canvas.drawLine(
          end,
          Offset(
            end.dx - arrowLen * cos(angle - arrowAngle),
            end.dy - arrowLen * sin(angle - arrowAngle),
          ),
          paint,
        );
        canvas.drawLine(
          end,
          Offset(
            end.dx - arrowLen * cos(angle + arrowAngle),
            end.dy - arrowLen * sin(angle + arrowAngle),
          ),
          paint,
        );
        break;

      case DrawingTool.circle:
        final start = e.points.first;
        final end = e.points.last;
        final center = Offset(
          (start.dx + end.dx) / 2,
          (start.dy + end.dy) / 2,
        );
        final radius = (end - start).distance / 2;
        canvas.drawCircle(center, radius, paint);
        break;

      case DrawingTool.rectangle:
        final rect = Rect.fromPoints(e.points.first, e.points.last);
        canvas.drawRect(rect, paint);
        break;

      case DrawingTool.none:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter old) => true;
}
