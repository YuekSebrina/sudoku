import '../../models/technique.dart';
import 'technique_utils.dart';

/// Expert-level techniques (进阶).
///
/// Includes: Strong Links (3) / Coloring, BUG Type 1, BUG Type 2,
/// VWXYZ-Wing, UVWXYZ-Wing.
class ExpertTechniques {
  // ---------------------------------------------------------------------------
  // Strong Links 3 (强链3数组) - Simple Coloring
  // ---------------------------------------------------------------------------

  static TechniqueResult? findStrongLinks3(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int n = 1; n <= 9; n++) {
      final conjugates = <CellPosition, List<CellPosition>>{};
      for (final group in TechniqueUtils.allGroups()) {
        final cells = group
            .where((p) => candidates[p.row][p.col].contains(n))
            .toList();
        if (cells.length == 2) {
          conjugates.putIfAbsent(cells[0], () => []).add(cells[1]);
          conjugates.putIfAbsent(cells[1], () => []).add(cells[0]);
        }
      }
      if (conjugates.isEmpty) continue;

      // BFS coloring
      final color = <CellPosition, int>{};
      for (final start in conjugates.keys) {
        if (color.containsKey(start)) continue;
        final queue = [start];
        color[start] = 0;
        int qi = 0;
        while (qi < queue.length) {
          final cur = queue[qi++];
          final curColor = color[cur]!;
          for (final next in conjugates[cur] ?? <CellPosition>[]) {
            if (!color.containsKey(next)) {
              color[next] = 1 - curColor;
              queue.add(next);
            }
          }
        }

        final color0 =
            queue.where((p) => color[p] == 0).toList();
        final color1 =
            queue.where((p) => color[p] == 1).toList();

        // Rule 1: Two same-color cells in same group → that color is false
        int? falseColor;
        for (final group in TechniqueUtils.allGroups()) {
          final g0 =
              color0.where((p) => group.contains(p)).toList();
          final g1 =
              color1.where((p) => group.contains(p)).toList();
          if (g0.length > 1) {
            falseColor = 0;
            break;
          }
          if (g1.length > 1) {
            falseColor = 1;
            break;
          }
        }

        if (falseColor != null) {
          final trueColor = 1 - falseColor;
          final trueCells =
              queue.where((p) => color[p] == trueColor).toList();
          final falseCells =
              queue.where((p) => color[p] == falseColor).toList();
          if (trueCells.length >= 2) {
            final elim = <CellPosition, Set<int>>{};
            for (final p in falseCells) {
              elim[p] = {n};
            }
            if (elim.isNotEmpty) {
              return TechniqueResult(
                type: TechniqueType.strongLinks3,
                description:
                    '数字 $n 的着色推理：同色格冲突，可确定另一色为真，删除假色候选数',
                highlightCells: trueCells,
                relatedCells: falseCells,
                eliminateCandidates: elim,
                targetNumber: n,
              );
            }
          }
        }

        // Rule 2: Cell sees both colors → can eliminate n
        final elim = <CellPosition, Set<int>>{};
        for (int rr = 0; rr < 9; rr++) {
          for (int cc = 0; cc < 9; cc++) {
            if (!candidates[rr][cc].contains(n)) continue;
            final p = CellPosition(rr, cc);
            if (color.containsKey(p)) continue;
            final seesColor0 =
                color0.any((cp) => TechniqueUtils.sees(p, cp));
            final seesColor1 =
                color1.any((cp) => TechniqueUtils.sees(p, cp));
            if (seesColor0 && seesColor1) {
              elim[p] = {n};
            }
          }
        }
        if (elim.isNotEmpty) {
          return TechniqueResult(
            type: TechniqueType.strongLinks3,
            description:
                '数字 $n 的强链着色：某格同时看到两种颜色，可删除该格的候选数 $n',
            highlightCells: [...color0, ...color1],
            relatedCells: elim.keys.toList(),
            eliminateCandidates: elim,
            targetNumber: n,
          );
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // BUG1 (二向值坟墓 Type 1)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findBUG1(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    CellPosition? triCell;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] != 0) continue;
        final len = candidates[r][c].length;
        if (len == 2) continue;
        if (len == 3 && triCell == null) {
          triCell = CellPosition(r, c);
        } else {
          return null;
        }
      }
    }
    if (triCell == null) return null;

    final cands = candidates[triCell.row][triCell.col].toList();
    for (final n in cands) {
      int rowCount = 0, colCount = 0, boxCount = 0;
      for (int c = 0; c < 9; c++) {
        if (candidates[triCell.row][c].contains(n)) rowCount++;
      }
      for (int r = 0; r < 9; r++) {
        if (candidates[r][triCell.col].contains(n)) colCount++;
      }
      final br = (triCell.row ~/ 3) * 3, bc = (triCell.col ~/ 3) * 3;
      for (int r = br; r < br + 3; r++) {
        for (int c = bc; c < bc + 3; c++) {
          if (candidates[r][c].contains(n)) boxCount++;
        }
      }
      if (rowCount % 2 == 1 || colCount % 2 == 1 || boxCount % 2 == 1) {
        return TechniqueResult(
          type: TechniqueType.bug1,
          description:
              '除 R${triCell.row + 1}C${triCell.col + 1} 外所有未解格都是二值格（BUG状态），'
              '该格必须填 $n 以避免死局',
          highlightCells: [triCell],
          placements: {triCell: n},
          targetNumber: n,
        );
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // BUG2 (二向值坟墓 Type 2)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findBUG2(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    final triCells = <CellPosition>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] != 0) continue;
        final len = candidates[r][c].length;
        if (len == 2) continue;
        if (len == 3) {
          triCells.add(CellPosition(r, c));
        } else {
          return null;
        }
      }
    }
    if (triCells.length != 2) return null;

    final c1 = candidates[triCells[0].row][triCells[0].col];
    final c2 = candidates[triCells[1].row][triCells[1].col];
    final common = c1.intersection(c2);
    if (common.isEmpty) return null;

    if (!TechniqueUtils.sees(triCells[0], triCells[1])) return null;

    for (final n in common) {
      bool isExtra = false;
      if (triCells[0].row == triCells[1].row) {
        int count = 0;
        for (int c = 0; c < 9; c++) {
          if (candidates[triCells[0].row][c].contains(n)) count++;
        }
        if (count % 2 == 0) isExtra = true;
      }
      if (triCells[0].col == triCells[1].col) {
        int count = 0;
        for (int r = 0; r < 9; r++) {
          if (candidates[r][triCells[0].col].contains(n)) count++;
        }
        if (count % 2 == 0) isExtra = true;
      }
      if (triCells[0].boxIndex == triCells[1].boxIndex) {
        final br = triCells[0].boxRow, bc = triCells[0].boxCol;
        int count = 0;
        for (int r = br; r < br + 3; r++) {
          for (int c = bc; c < bc + 3; c++) {
            if (candidates[r][c].contains(n)) count++;
          }
        }
        if (count % 2 == 0) isExtra = true;
      }
      if (isExtra) {
        final elim = <CellPosition, Set<int>>{};
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (!candidates[r][c].contains(n)) continue;
            final p = CellPosition(r, c);
            if (p == triCells[0] || p == triCells[1]) continue;
            if (TechniqueUtils.sees(p, triCells[0]) &&
                TechniqueUtils.sees(p, triCells[1])) {
              elim[p] = {n};
            }
          }
        }
        if (elim.isNotEmpty) {
          return TechniqueResult(
            type: TechniqueType.bug2,
            description:
                'BUG+2 状态：两个三值格共享多余数字 $n，'
                '可从能看到两格的位置删除 $n',
            highlightCells: triCells,
            relatedCells: elim.keys.toList(),
            eliminateCandidates: elim,
            targetNumber: n,
          );
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // VWXYZ-Wing / UVWXYZ-Wing (larger wings)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findVWXYZWing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    return _findLargeWing(
        grid, candidates, 5, TechniqueType.vwxyzWing, 'VWXYZ-Wing');
  }

  static TechniqueResult? findUVWXYZWing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    return _findLargeWing(
        grid, candidates, 6, TechniqueType.uvwxyzWing, 'UVWXYZ-Wing');
  }

  static TechniqueResult? _findLargeWing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
    int wingSize,
    TechniqueType type,
    String name,
  ) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final pivotCands = candidates[r][c];
        if (pivotCands.length != wingSize - 1 &&
            pivotCands.length != wingSize) continue;
        if (pivotCands.isEmpty) continue;
        final pivot = CellPosition(r, c);
        final peerList = TechniqueUtils.peers(r, c)
            .where((p) =>
                candidates[p.row][p.col].length == 2 &&
                candidates[p.row][p.col]
                    .intersection(pivotCands)
                    .isNotEmpty)
            .toList();

        if (peerList.length < wingSize - 1) continue;

        final combos =
            TechniqueUtils.combinations(peerList, wingSize - 1);
        for (final combo in combos) {
          final allCands = <int>{...pivotCands};
          for (final w in combo) {
            allCands.addAll(candidates[w.row][w.col]);
          }
          if (allCands.length != wingSize) continue;

          Set<int> commonInWings =
              Set.from(candidates[combo[0].row][combo[0].col]);
          for (int i = 1; i < combo.length; i++) {
            commonInWings = commonInWings
                .intersection(candidates[combo[i].row][combo[i].col]);
          }
          commonInWings = commonInWings.intersection(pivotCands);
          if (commonInWings.isEmpty) continue;

          for (final z in commonInWings) {
            final allCells = [pivot, ...combo];
            final elim = <CellPosition, Set<int>>{};
            for (int rr = 0; rr < 9; rr++) {
              for (int cc = 0; cc < 9; cc++) {
                if (!candidates[rr][cc].contains(z)) continue;
                final p = CellPosition(rr, cc);
                if (allCells.contains(p)) continue;
                if (allCells.every((cp) => TechniqueUtils.sees(p, cp))) {
                  elim[p] = {z};
                }
              }
            }
            if (elim.isNotEmpty) {
              return TechniqueResult(
                type: type,
                description:
                    '以 R${r + 1}C${c + 1} 为中心的 $name 结构，'
                    '可从能看到所有组成格的位置删除 $z',
                highlightCells: allCells,
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: z,
              );
            }
          }
        }
      }
    }
    return null;
  }
}
