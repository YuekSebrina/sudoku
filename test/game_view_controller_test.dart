import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/controllers/game_view_controller.dart';

void main() {
  test('drawingColor defaults to red and can be updated', () {
    final controller = GameViewController();

    expect(controller.drawingColor, const Color(0xFFE53935));

    controller.setDrawingColor(const Color(0xFF1E88E5));

    expect(controller.drawingColor, const Color(0xFF1E88E5));
    controller.dispose();
  });
}
