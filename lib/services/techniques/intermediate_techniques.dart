import '../../models/technique.dart';
import 'technique_utils.dart';

/// Intermediate-level techniques (中级).
///
/// Includes: Naked Single, Explicit Pointing, Naked Pair,
/// Hidden Pointing, Line→Box Claiming.
class IntermediateTechniques {
  // ---------------------------------------------------------------------------
  // Naked Single (唯一余数)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findNakedSingle(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (candidates[r][c].length == 1) {
          final n = candidates[r][c].first;
          final pos = CellPosition(r, c);
          final related = <CellPosition>[];
          for (int i = 0; i < 9; i++) {
            if (i != c) related.add(CellPosition(r, i));
            if (i != r) related.add(CellPosition(i, c));
          }
          final br = (r ~/ 3) * 3, bc = (c ~/ 3) * 3;
          for (int dr = 0; dr < 3; dr++) {
            for (int dc = 0; dc < 3; dc++) {
              final rr = br + dr, cc = bc + dc;
              if (rr != r || cc != c) {
                final p = CellPosition(rr, cc);
                if (!related.contains(p)) related.add(p);
              }
            }
          }
          return TechniqueResult(
            type: TechniqueType.nakedSingle,
            description:
                'R${r + 1}C${c + 1} 的候选数只剩 $n，因此该格填入 $n',
            highlightCells: [pos],
            relatedCells: related,
            placements: {pos: n},
            targetNumber: n,
          );
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Explicit Pointing (宫对行列区块摒除法 - 显性)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findExplicitPointing(
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
          if (positions.length != 2 && positions.length != 3) continue;

          // Pointing in row
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
                type: TechniqueType.explicitBoxLineReduction,
                description:
                    '在第${br ~/ 3 + 1}行第${bc ~/ 3 + 1}列宫中，数字 $n 的 ${positions.length} 个候选位置都在第${row + 1}行，'
                    '形成显性区块摒除，可从该行其他位置删除 $n',
                highlightCells: positions,
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: n,
              );
            }
          }

          // Pointing in col
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
                type: TechniqueType.explicitBoxLineReduction,
                description:
                    '在第${br ~/ 3 + 1}行第${bc ~/ 3 + 1}列宫中，数字 $n 的 ${positions.length} 个候选位置都在第${col + 1}列，'
                    '形成显性区块摒除，可从该列其他位置删除 $n',
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
  // Naked Pair (直观2数对)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findNakedPair(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (final group in TechniqueUtils.allGroups()) {
      final cells = group
          .where((p) => candidates[p.row][p.col].length == 2)
          .toList();
      for (int i = 0; i < cells.length; i++) {
        for (int j = i + 1; j < cells.length; j++) {
          final c1 = candidates[cells[i].row][cells[i].col];
          final c2 = candidates[cells[j].row][cells[j].col];
          if (c1.length == 2 && c1.containsAll(c2) && c2.containsAll(c1)) {
            final pair = c1;
            final elim = <CellPosition, Set<int>>{};
            for (final p in group) {
              if (p != cells[i] && p != cells[j]) {
                final toRemove =
                    candidates[p.row][p.col].intersection(pair);
                if (toRemove.isNotEmpty) {
                  elim[p] = toRemove;
                }
              }
            }
            if (elim.isNotEmpty) {
              return TechniqueResult(
                type: TechniqueType.nakedPair,
                description:
                    'R${cells[i].row + 1}C${cells[i].col + 1} 和 R${cells[j].row + 1}C${cells[j].col + 1} '
                    '形成数对 {${pair.join(",")}}，可从同组其他格中删除这些数字',
                highlightCells: [cells[i], cells[j]],
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
              );
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Hidden Pointing (宫对行列区块摒除法 - 隐性)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findHiddenPointing(
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
          if (positions.length < 2 || positions.length > 3) continue;
          final hasOthers =
              positions.any((p) => candidates[p.row][p.col].length > 1);
          if (!hasOthers) continue;

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
                type: TechniqueType.hiddenBoxLineReduction,
                description:
                    '在第${br ~/ 3 + 1}行第${bc ~/ 3 + 1}列宫中，数字 $n 的候选位置都在第${row + 1}行（隐性区块摒除），'
                    '可从该行其他位置删除 $n',
                highlightCells: positions,
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: n,
              );
            }
          }

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
                type: TechniqueType.hiddenBoxLineReduction,
                description:
                    '在第${br ~/ 3 + 1}行第${bc ~/ 3 + 1}列宫中，数字 $n 的候选位置都在第${col + 1}列（隐性区块摒除），'
                    '可从该列其他位置删除 $n',
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
  // Line→Box Claiming (行列对宫区块摒除法 - 隐性)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findLineBoxClaiming(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // Row claiming
    for (int r = 0; r < 9; r++) {
      for (int n = 1; n <= 9; n++) {
        final positions = <CellPosition>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) {
            positions.add(CellPosition(r, c));
          }
        }
        if (positions.length < 2) continue;
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
              type: TechniqueType.lineBoxClaiming,
              description:
                  '第${r + 1}行中，数字 $n 只出现在第${bc ~/ 3 + 1}宫内（行列区块摒除），'
                  '可从该宫其他行中删除 $n',
              highlightCells: positions,
              relatedCells: elim.keys.toList(),
              eliminateCandidates: elim,
              targetNumber: n,
            );
          }
        }
      }
    }

    // Col claiming
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
              type: TechniqueType.lineBoxClaiming,
              description:
                  '第${c + 1}列中，数字 $n 只出现在第${br ~/ 3 + 1}宫内（行列区块摒除），'
                  '可从该宫其他列中删除 $n',
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
