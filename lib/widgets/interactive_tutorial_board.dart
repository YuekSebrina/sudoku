import 'package:flutter/material.dart';

import '../models/technique.dart';
import '../theme/app_theme.dart';

class TutorialColors {
  static const Color highlightCell = Color(0xFF4CAF50);
  static const Color relatedCell = Color(0xFFFFC107);
  static const Color eliminateCell = Color(0xFFE53935);
  static const Color highlightCellBg = Color(0x3349BE4B);
  static const Color relatedCellBg = Color(0x33FFC107);
  static const Color eliminateCellBg = Color(0x33E53935);
  static const Color eliminateCandidate = Color(0xFFE53935);
  static const Color placementDigit = Color(0xFF4CAF50);
  static const Color regionBorderRow = Color(0xFFE53935);
  static const Color regionBorderCol = Color(0xFF1565C0);
  static const Color regionBorderBox = Color(0xFFE53935);
}

enum RegionType { box, row, col }

class HighlightRegion {
  final RegionType type;
  final int index;
  const HighlightRegion(this.type, this.index);

  Color get color {
    switch (type) {
      case RegionType.row:
        return TutorialColors.regionBorderRow;
      case RegionType.col:
        return TutorialColors.regionBorderCol;
      case RegionType.box:
        return TutorialColors.regionBorderBox;
    }
  }
}

class InteractiveTutorialBoard extends StatelessWidget {
  final List<List<int>> boardValues;
  final List<List<Set<int>>> boardCandidates;
  final TechniqueResult? techniqueResult;
  final bool showEliminations;
  final CellPosition? selectedCell;
  final ValueChanged<CellPosition>? onCellTap;

  /// Explicitly provided regions to highlight with a red border.
  /// If null, regions are auto-computed from [techniqueResult].
  final List<HighlightRegion>? regions;

  /// Original board values to distinguish fixed cells from user-entered ones.
  /// User-entered values are shown in blue instead of black.
  final List<List<int>>? originalValues;

  const InteractiveTutorialBoard({
    super.key,
    required this.boardValues,
    required this.boardCandidates,
    this.techniqueResult,
    this.showEliminations = false,
    this.selectedCell,
    this.onCellTap,
    this.regions,
    this.originalValues,
  });

  /// Auto-compute regions from the technique result.
  List<HighlightRegion> get _highlightRegions {
    if (techniqueResult == null) return [];
    return computeRegionsForTechnique(techniqueResult!);
  }

  @override
  Widget build(BuildContext context) {
    final regions = this.regions ?? _highlightRegions;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.boxLineColor, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = constraints.maxWidth / 9;
              return Stack(
                children: [
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 9,
                    ),
                    itemCount: 81,
                    itemBuilder: (context, index) {
                      final row = index ~/ 9;
                      final col = index % 9;
                      return _buildCell(row, col, regions);
                    },
                  ),
                  // Region border overlay
                  if (regions.isNotEmpty)
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _RegionBorderPainter(
                          regions: regions,
                          cellSize: cellSize,
                        ),
                      ),
                    ),
                  // Lines/arrows overlay
                  if (techniqueResult != null && techniqueResult!.lines.isNotEmpty)
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _LinePainter(
                          lines: techniqueResult!.lines,
                          cellSize: cellSize,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  _CellHighlightType _getCellHighlight(int row, int col) {
    if (techniqueResult == null) return _CellHighlightType.none;
    final pos = CellPosition(row, col);

    if (showEliminations && techniqueResult!.eliminateCandidates.containsKey(pos)) {
      return _CellHighlightType.eliminate;
    }
    if (techniqueResult!.placements.containsKey(pos)) {
      return _CellHighlightType.highlight;
    }
    if (techniqueResult!.highlightCells.contains(pos)) {
      return _CellHighlightType.highlight;
    }
    if (techniqueResult!.relatedCells.contains(pos)) {
      return _CellHighlightType.related;
    }
    return _CellHighlightType.none;
  }

  bool _isSelected(int row, int col) {
    return selectedCell != null && selectedCell!.row == row && selectedCell!.col == col;
  }

  bool _isRelatedToSelected(int row, int col) {
    if (selectedCell == null) return false;
    final sr = selectedCell!.row, sc = selectedCell!.col;
    if (row == sr || col == sc) return true;
    if ((row ~/ 3 == sr ~/ 3) && (col ~/ 3 == sc ~/ 3)) return true;
    return false;
  }

  /// The value of the selected cell (0 if empty or no selection).
  int get _selectedValue {
    if (selectedCell == null) return 0;
    return boardValues[selectedCell!.row][selectedCell!.col];
  }

  bool _isSameNumber(int row, int col) {
    final sv = _selectedValue;
    if (sv == 0) return false;
    return boardValues[row][col] == sv && !_isSelected(row, col);
  }

  /// A cell is "fixed" if it was in the original puzzle.
  /// If [originalValues] is not provided, all non-zero cells are treated as fixed.
  bool _isFixedCell(int row, int col) {
    if (originalValues == null) return true;
    return originalValues![row][col] != 0;
  }

  Widget _buildCell(int row, int col, List<HighlightRegion> regions) {
    final value = boardValues[row][col];
    final candidates = boardCandidates[row][col];
    final highlight = _getCellHighlight(row, col);
    final pos = CellPosition(row, col);
    final selected = _isSelected(row, col);
    final relatedToSel = _isRelatedToSelected(row, col);

    final isSameNum = _isSameNumber(row, col);

    Color bgColor;
    if (selected) {
      bgColor = AppTheme.selectedCellColor;
    } else if (isSameNum) {
      bgColor = AppTheme.sameNumberHighlight;
    } else if (highlight != _CellHighlightType.none) {
      switch (highlight) {
        case _CellHighlightType.highlight:
          bgColor = TutorialColors.highlightCellBg;
        case _CellHighlightType.related:
          bgColor = TutorialColors.relatedCellBg;
        case _CellHighlightType.eliminate:
          bgColor = TutorialColors.eliminateCellBg;
        case _CellHighlightType.none:
          bgColor = AppTheme.cellBackground;
      }
    } else if (relatedToSel) {
      bgColor = AppTheme.highlightedCellColor;
    } else {
      bgColor = AppTheme.cellBackground;
    }

    Set<int> eliminatedCandidates = {};
    if (showEliminations && techniqueResult != null) {
      eliminatedCandidates = techniqueResult!.eliminateCandidates[pos] ?? {};
    }

    int? placedValue;
    if (showEliminations && techniqueResult != null) {
      placedValue = techniqueResult!.placements[pos];
    }

    return GestureDetector(
      onTap: onCellTap != null ? () => onCellTap!(pos) : null,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(
              color: row % 3 == 0 ? AppTheme.boxLineColor : AppTheme.gridLineColor,
              width: row % 3 == 0 ? 2.0 : 1.0,
            ),
            left: BorderSide(
              color: col % 3 == 0 ? AppTheme.boxLineColor : AppTheme.gridLineColor,
              width: col % 3 == 0 ? 2.0 : 1.0,
            ),
            bottom: BorderSide(
              color: row == 8 ? AppTheme.boxLineColor : Colors.transparent,
              width: row == 8 ? 2.0 : 0,
            ),
            right: BorderSide(
              color: col == 8 ? AppTheme.boxLineColor : Colors.transparent,
              width: col == 8 ? 2.0 : 0,
            ),
          ),
        ),
        child: Center(
          child: placedValue != null
              ? Text(
                  '$placedValue',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: TutorialColors.placementDigit),
                )
              : value != 0
                  ? Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: _isFixedCell(row, col) ? FontWeight.bold : FontWeight.w500,
                        color: highlight == _CellHighlightType.highlight
                            ? TutorialColors.highlightCell
                            : _isFixedCell(row, col)
                                ? AppTheme.fixedTextColor
                                : AppTheme.userTextColor,
                      ),
                    )
                  : candidates.isNotEmpty
                      ? _buildCandidates(candidates, eliminatedCandidates, highlight)
                      : null,
        ),
      ),
    );
  }

  Widget _buildCandidates(Set<int> candidates, Set<int> eliminated, _CellHighlightType highlight) {
    final targetNumber = techniqueResult?.targetNumber ?? 0;
    final selValue = _selectedValue;
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Column(
        children: List.generate(3, (row) {
          return Expanded(
            child: Row(
              children: List.generate(3, (col) {
                final number = row * 3 + col + 1;
                final hasCandidate = candidates.contains(number);
                final isEliminated = eliminated.contains(number);
                final isTarget = hasCandidate && number == targetNumber;
                final isSelectedNum = hasCandidate && selValue > 0 && number == selValue;

                Color textColor = AppTheme.notesTextColor;
                FontWeight weight = FontWeight.normal;
                TextDecoration? decoration;
                bool showHighlightBg = false;

                if (isEliminated) {
                  textColor = TutorialColors.eliminateCandidate;
                  decoration = TextDecoration.lineThrough;
                  weight = FontWeight.bold;
                } else if (isTarget && highlight == _CellHighlightType.highlight) {
                  textColor = TutorialColors.highlightCell;
                  weight = FontWeight.bold;
                  showHighlightBg = true;
                } else if (isTarget) {
                  textColor = AppTheme.primaryColor;
                  weight = FontWeight.bold;
                  showHighlightBg = true;
                } else if (isSelectedNum) {
                  textColor = AppTheme.primaryColor;
                  weight = FontWeight.bold;
                  showHighlightBg = true;
                }

                return Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: showHighlightBg
                        ? BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          )
                        : null,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        hasCandidate || isEliminated ? '$number' : '',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: weight,
                          color: textColor,
                          decoration: decoration,
                          decorationColor: TutorialColors.eliminateCandidate,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

enum _CellHighlightType { none, highlight, related, eliminate }

/// Compute highlight regions from a TechniqueResult.
/// Shows ALL involved regions: source region + affected rows/cols/boxes.
List<HighlightRegion> computeRegionsForTechnique(TechniqueResult result) {
  if (result.highlightCells.isEmpty && result.relatedCells.isEmpty) return [];
  final cells = result.highlightCells;
  final elim = result.eliminateCandidates.keys;

  switch (result.type) {
    // Box → row/col: source box (red) + affected row or col
    case TechniqueType.boxHiddenSingle:
      return [HighlightRegion(RegionType.box, cells.first.boxIndex)];

    case TechniqueType.boxElimination:
    case TechniqueType.explicitBoxLineReduction:
    case TechniqueType.hiddenBoxLineReduction:
      final regions = <HighlightRegion>[
        HighlightRegion(RegionType.box, cells.first.boxIndex),
      ];
      // Also highlight the affected row or col
      if (cells.every((c) => c.row == cells.first.row)) {
        regions.add(HighlightRegion(RegionType.row, cells.first.row));
      } else if (cells.every((c) => c.col == cells.first.col)) {
        regions.add(HighlightRegion(RegionType.col, cells.first.col));
      }
      return regions;

    case TechniqueType.rowHiddenSingle:
      return [HighlightRegion(RegionType.row, cells.first.row)];

    case TechniqueType.rowElimination:
      final regions = <HighlightRegion>[
        HighlightRegion(RegionType.row, cells.first.row),
      ];
      if (elim.isNotEmpty) {
        regions.add(HighlightRegion(RegionType.box, elim.first.boxIndex));
      }
      return regions;

    case TechniqueType.colHiddenSingle:
      return [HighlightRegion(RegionType.col, cells.first.col)];

    case TechniqueType.colElimination:
      final regions = <HighlightRegion>[
        HighlightRegion(RegionType.col, cells.first.col),
      ];
      if (elim.isNotEmpty) {
        regions.add(HighlightRegion(RegionType.box, elim.first.boxIndex));
      }
      return regions;

    // Line → Box claiming: line + affected box
    case TechniqueType.lineBoxClaiming:
      final first = cells.first;
      final regions = <HighlightRegion>[];
      if (cells.length >= 2 && cells.every((c) => c.row == first.row)) {
        regions.add(HighlightRegion(RegionType.row, first.row));
      } else if (cells.length >= 2 && cells.every((c) => c.col == first.col)) {
        regions.add(HighlightRegion(RegionType.col, first.col));
      }
      if (elim.isNotEmpty) {
        regions.add(HighlightRegion(RegionType.box, elim.first.boxIndex));
      }
      return regions;

    // Naked/Hidden pairs/triples: highlight the group
    case TechniqueType.nakedSingle:
      return [
        HighlightRegion(RegionType.row, cells.first.row),
        HighlightRegion(RegionType.col, cells.first.col),
        HighlightRegion(RegionType.box, cells.first.boxIndex),
      ];

    case TechniqueType.nakedPair:
    case TechniqueType.nakedTriple:
    case TechniqueType.explicitNakedTriple:
    case TechniqueType.hiddenPair:
    case TechniqueType.hiddenTriple:
      if (cells.every((c) => c.row == cells.first.row)) {
        return [HighlightRegion(RegionType.row, cells.first.row)];
      }
      if (cells.every((c) => c.col == cells.first.col)) {
        return [HighlightRegion(RegionType.col, cells.first.col)];
      }
      if (cells.every((c) => c.boxIndex == cells.first.boxIndex)) {
        return [HighlightRegion(RegionType.box, cells.first.boxIndex)];
      }
      return [];

    // X-Wing, Swordfish: rows (red) + cols (blue)
    case TechniqueType.xWing:
    case TechniqueType.swordfish:
    case TechniqueType.skyscraper:
      final rows = cells.map((c) => c.row).toSet();
      final cols = cells.map((c) => c.col).toSet();
      return [
        ...rows.map((r) => HighlightRegion(RegionType.row, r)),
        ...cols.map((c) => HighlightRegion(RegionType.col, c)),
      ];

    // Wing techniques: highlight the box of the pivot
    case TechniqueType.xyWing:
    case TechniqueType.xyzWing:
    case TechniqueType.vwxyzWing:
    case TechniqueType.uvwxyzWing:
      if (cells.isNotEmpty) {
        return [HighlightRegion(RegionType.box, cells.first.boxIndex)];
      }
      return [];

    // Strong links: highlight involved rows + cols
    case TechniqueType.strongLinks2:
    case TechniqueType.strongLinks3:
      final rows = cells.map((c) => c.row).toSet();
      final cols = cells.map((c) => c.col).toSet();
      return [
        ...rows.map((r) => HighlightRegion(RegionType.row, r)),
        ...cols.map((c) => HighlightRegion(RegionType.col, c)),
      ];

    // BUG: highlight the special cell's regions
    case TechniqueType.bug1:
    case TechniqueType.bug2:
      if (cells.isNotEmpty) {
        return [
          HighlightRegion(RegionType.row, cells.first.row),
          HighlightRegion(RegionType.col, cells.first.col),
          HighlightRegion(RegionType.box, cells.first.boxIndex),
        ];
      }
      return [];

    // Chain techniques: no specific region
    case TechniqueType.biDirectionalXCycle:
    case TechniqueType.biDirectionalCycle:
    case TechniqueType.cellForcingChain:
    case TechniqueType.regionForcingChain:
      return [];
  }
}

/// Draws colored borders around highlighted regions.
/// Row = red, Col = blue, Box = red.
class _RegionBorderPainter extends CustomPainter {
  final List<HighlightRegion> regions;
  final double cellSize;

  _RegionBorderPainter({required this.regions, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      final paint = Paint()
        ..color = region.color
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      switch (region.type) {
        case RegionType.box:
          final boxRow = (region.index ~/ 3) * 3;
          final boxCol = (region.index % 3) * 3;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(boxCol * cellSize, boxRow * cellSize, 3 * cellSize, 3 * cellSize),
              const Radius.circular(2),
            ),
            paint,
          );
        case RegionType.row:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(0, region.index * cellSize, 9 * cellSize, cellSize),
              const Radius.circular(2),
            ),
            paint,
          );
        case RegionType.col:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(region.index * cellSize, 0, cellSize, 9 * cellSize),
              const Radius.circular(2),
            ),
            paint,
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RegionBorderPainter old) {
    return regions != old.regions || cellSize != old.cellSize;
  }
}

class _LinePainter extends CustomPainter {
  final List<HighlightLine> lines;
  final double cellSize;

  _LinePainter({required this.lines, required this.cellSize});

  /// Get the position of a specific candidate digit within a cell.
  /// Digit n (1-9) occupies a 3x3 sub-grid within the cell.
  Offset _candidateOffset(CellPosition cell, int digit) {
    if (digit <= 0) {
      return Offset((cell.col + 0.5) * cellSize, (cell.row + 0.5) * cellSize);
    }
    final candRow = (digit - 1) ~/ 3;
    final candCol = (digit - 1) % 3;
    final subSize = cellSize / 3;
    return Offset(
      cell.col * cellSize + (candCol + 0.5) * subSize,
      cell.row * cellSize + (candRow + 0.5) * subSize,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // First pass: draw circles around linked candidate digits
    final circledPositions = <(CellPosition, int)>{};
    for (final line in lines) {
      if (line.digit > 0) {
        circledPositions.add((line.from, line.digit));
        circledPositions.add((line.to, line.digit));
      }
    }
    for (final (cell, digit) in circledPositions) {
      final center = _candidateOffset(cell, digit);
      final radius = cellSize / 6 - 1;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = TutorialColors.regionBorderCol
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke,
      );
    }

    // Second pass: draw lines/arrows between candidates
    for (final line in lines) {
      final paint = Paint()
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      switch (line.style) {
        case HighlightLineStyle.solid:
          paint.color = TutorialColors.regionBorderCol.withValues(alpha: 0.8);
        case HighlightLineStyle.dashed:
          paint.color = Colors.grey.withValues(alpha: 0.6);
          paint.strokeWidth = 1.5;
        case HighlightLineStyle.arrow:
          paint.color = TutorialColors.regionBorderRow.withValues(alpha: 0.8);
      }

      final fromPt = _candidateOffset(line.from, line.digit);
      final toPt = _candidateOffset(line.to, line.digit);

      // Shorten the line so it doesn't overlap the circles
      Offset actualFrom = fromPt, actualTo = toPt;
      if (line.digit > 0) {
        final dir = toPt - fromPt;
        final len = dir.distance;
        if (len > 0) {
          final unit = dir / len;
          final radius = cellSize / 6;
          actualFrom = fromPt + unit * radius;
          actualTo = toPt - unit * radius;
        }
      }

      if (line.style == HighlightLineStyle.arrow) {
        canvas.drawLine(actualFrom, actualTo, paint);
        _drawArrowHead(canvas, actualFrom, actualTo, paint);
      } else if (line.style == HighlightLineStyle.dashed) {
        _drawDashedLine(canvas, actualFrom, actualTo, paint);
      } else {
        canvas.drawLine(actualFrom, actualTo, paint);
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    final direction = (to - from);
    final length = direction.distance;
    if (length < 2) return;
    final unit = direction / length;
    final normal = Offset(-unit.dy, unit.dx);
    const arrowSize = 6.0;
    final tip = to;
    final left = tip - unit * arrowSize + normal * arrowSize * 0.5;
    final right = tip - unit * arrowSize - normal * arrowSize * 0.5;
    canvas.drawPath(
      Path()..moveTo(tip.dx, tip.dy)..lineTo(left.dx, left.dy)..lineTo(right.dx, right.dy)..close(),
      Paint()..color = paint.color..style = PaintingStyle.fill,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final direction = to - from;
    final length = direction.distance;
    if (length < 1) return;
    final unit = direction / length;
    const dashLength = 5.0, gapLength = 3.0;
    double drawn = 0;
    while (drawn < length) {
      final start = from + unit * drawn;
      final end = from + unit * (drawn + dashLength).clamp(0, length);
      canvas.drawLine(start, end, paint);
      drawn += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => lines != old.lines || cellSize != old.cellSize;
}
