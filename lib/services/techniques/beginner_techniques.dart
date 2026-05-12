import '../../models/technique.dart';
import 'technique_utils.dart';

/// Beginner-level techniques (初级).
///
/// Includes: Box Hidden Single, Row Hidden Single, Col Hidden Single,
/// Box Elimination, Row Elimination, Col Elimination.
class BeginnerTechniques {
  // ---------------------------------------------------------------------------
  // Box Hidden Single (宫唯一数)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findBoxHiddenSingle(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int br = 0; br < 9; br += 3) {
      for (int bc = 0; bc < 9; bc += 3) {
        for (int n = 1; n <= 9; n++) {
          final positions = <CellPosition>[];
          for (int r = br; r < br + 3; r++) {
            for (int c = bc; c < bc + 3; c++) {
              if (candidates[r][c].contains(n)) {
                positions.add(CellPosition(r, c));
              }
            }
          }
          if (positions.length == 1) {
            final pos = positions[0];
            final boxCells = TechniqueUtils.boxCells(br, bc)
                .where((p) => !(p.row == pos.row && p.col == pos.col))
                .toList();
            return TechniqueResult(
              type: TechniqueType.boxHiddenSingle,
              description:
                  '在第${br ~/ 3 + 1}行第${bc ~/ 3 + 1}列宫中，数字 $n 只能放在 R${pos.row + 1}C${pos.col + 1}',
              highlightCells: [pos],
              relatedCells: boxCells,
              placements: {pos: n},
              targetNumber: n,
            );
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Row Hidden Single (行唯一数)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findRowHiddenSingle(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int r = 0; r < 9; r++) {
      for (int n = 1; n <= 9; n++) {
        final positions = <CellPosition>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) {
            positions.add(CellPosition(r, c));
          }
        }
        if (positions.length == 1) {
          final pos = positions[0];
          final rowCells = TechniqueUtils.rowCells(r)
              .where((p) => p.col != pos.col)
              .toList();
          return TechniqueResult(
            type: TechniqueType.rowHiddenSingle,
            description:
                '在第${r + 1}行中，数字 $n 只能放在 R${pos.row + 1}C${pos.col + 1}',
            highlightCells: [pos],
            relatedCells: rowCells,
            placements: {pos: n},
            targetNumber: n,
          );
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Column Hidden Single (列唯一数)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findColHiddenSingle(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int c = 0; c < 9; c++) {
      for (int n = 1; n <= 9; n++) {
        final positions = <CellPosition>[];
        for (int r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) {
            positions.add(CellPosition(r, c));
          }
        }
        if (positions.length == 1) {
          final pos = positions[0];
          final colCells = TechniqueUtils.colCells(c)
              .where((p) => p.row != pos.row)
              .toList();
          return TechniqueResult(
            type: TechniqueType.colHiddenSingle,
            description:
                '在第${c + 1}列中，数字 $n 只能放在 R${pos.row + 1}C${pos.col + 1}',
            highlightCells: [pos],
            relatedCells: colCells,
            placements: {pos: n},
            targetNumber: n,
          );
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Box Elimination (宫摒除法)
  // A digit in a box is restricted to one row/col, eliminating from that
  // row/col outside the box.
  // ---------------------------------------------------------------------------

  static TechniqueResult? findBoxElimination(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int br = 0; br < 9; br += 3) {
      for (int bc = 0; bc < 9; bc += 3) {
        for (int n = 1; n <= 9; n++) {
          final positions = <CellPosition>[];
          for (int r = br; r < br + 3; r++) {
            for (int c = bc; c < bc + 3; c++) {
              if (candidates[r][c].contains(n)) {
                positions.add(CellPosition(r, c));
              }
            }
          }
          if (positions.length < 2) continue;

          // All in same row → eliminate from that row outside this box
          if (positions.every((p) => p.row == positions[0].row)) {
            final row = positions[0].row;
            final elim = <CellPosition, Set<int>>{};
            for (int c = 0; c < 9; c++) {
              if (c < bc || c >= bc + 3) {
                if (candidates[row][c].contains(n)) {
                  elim[CellPosition(row, c)] = {n};
                }
              }
            }
            if (elim.isNotEmpty) {
              return TechniqueResult(
                type: TechniqueType.boxElimination,
                description:
                    '在第${br ~/ 3 + 1}行第${bc ~/ 3 + 1}列宫中，数字 $n 只出现在第${row + 1}行，'
                    '因此可以从第${row + 1}行的其他宫中删除 $n',
                highlightCells: positions,
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: n,
              );
            }
          }

          // All in same col → eliminate from that col outside this box
          if (positions.every((p) => p.col == positions[0].col)) {
            final col = positions[0].col;
            final elim = <CellPosition, Set<int>>{};
            for (int r = 0; r < 9; r++) {
              if (r < br || r >= br + 3) {
                if (candidates[r][col].contains(n)) {
                  elim[CellPosition(r, col)] = {n};
                }
              }
            }
            if (elim.isNotEmpty) {
              return TechniqueResult(
                type: TechniqueType.boxElimination,
                description:
                    '在第${br ~/ 3 + 1}行第${bc ~/ 3 + 1}列宫中，数字 $n 只出现在第${col + 1}列，'
                    '因此可以从第${col + 1}列的其他宫中删除 $n',
                highlightCells: positions,
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: n,
              );
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Row Elimination (行摒除法)
  // A digit in a row is restricted to one box, eliminating from that box
  // outside the row.
  // ---------------------------------------------------------------------------

  static TechniqueResult? findRowElimination(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int r = 0; r < 9; r++) {
      for (int n = 1; n <= 9; n++) {
        final positions = <CellPosition>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) {
            positions.add(CellPosition(r, c));
          }
        }
        if (positions.length < 2) continue;

        // All in same box?
        final bc = (positions[0].col ~/ 3) * 3;
        if (positions.every((p) => (p.col ~/ 3) * 3 == bc)) {
          final br = (r ~/ 3) * 3;
          final elim = <CellPosition, Set<int>>{};
          for (int row = br; row < br + 3; row++) {
            if (row == r) continue;
            for (int col = bc; col < bc + 3; col++) {
              if (candidates[row][col].contains(n)) {
                elim[CellPosition(row, col)] = {n};
              }
            }
          }
          if (elim.isNotEmpty) {
            return TechniqueResult(
              type: TechniqueType.rowElimination,
              description:
                  '在第${r + 1}行中，数字 $n 只出现在第${bc ~/ 3 + 1}宫内，'
                  '因此可以从该宫的其他行中删除 $n',
              highlightCells: positions,
              relatedCells: elim.keys.toList(),
              eliminateCandidates: elim,
              targetNumber: n,
            );
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Column Elimination (列摒除法)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findColElimination(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int c = 0; c < 9; c++) {
      for (int n = 1; n <= 9; n++) {
        final positions = <CellPosition>[];
        for (int r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) {
            positions.add(CellPosition(r, c));
          }
        }
        if (positions.length < 2) continue;

        final br = (positions[0].row ~/ 3) * 3;
        if (positions.every((p) => (p.row ~/ 3) * 3 == br)) {
          final bc = (c ~/ 3) * 3;
          final elim = <CellPosition, Set<int>>{};
          for (int col = bc; col < bc + 3; col++) {
            if (col == c) continue;
            for (int row = br; row < br + 3; row++) {
              if (candidates[row][col].contains(n)) {
                elim[CellPosition(row, col)] = {n};
              }
            }
          }
          if (elim.isNotEmpty) {
            return TechniqueResult(
              type: TechniqueType.colElimination,
              description:
                  '在第${c + 1}列中，数字 $n 只出现在第${br ~/ 3 + 1}宫内，'
                  '因此可以从该宫的其他列中删除 $n',
              highlightCells: positions,
              relatedCells: elim.keys.toList(),
              eliminateCandidates: elim,
              targetNumber: n,
            );
          }
        }
      }
    }
    return null;
  }
}
