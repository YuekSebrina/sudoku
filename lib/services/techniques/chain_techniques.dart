import '../../models/technique.dart';
import 'technique_utils.dart';

/// Chain-level techniques (链).
///
/// Includes: Bidirectional X-Cycle, Bidirectional Cycle (AIC),
/// Cell Forcing Chain, Region Forcing Chain.
class ChainTechniques {
  // ---------------------------------------------------------------------------
  // Bidirectional X-Cycle (双向X链)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findBiDirectionalXCycle(
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
      if (conjugates.length < 4) continue;

      for (final start in conjugates.keys) {
        final result = _dfsXCycle(
          n, start, start, true, [start], conjugates, candidates, grid, 0);
        if (result != null) return result;
      }
    }
    return null;
  }

  static TechniqueResult? _dfsXCycle(
    int n,
    CellPosition start,
    CellPosition current,
    bool lastWasStrong,
    List<CellPosition> path,
    Map<CellPosition, List<CellPosition>> conjugates,
    List<List<Set<int>>> candidates,
    List<List<int>> grid,
    int depth,
  ) {
    if (depth > 16) return null;

    if (lastWasStrong) {
      // Weak link: any peer with candidate n
      final peers = <CellPosition>[];
      for (final group in TechniqueUtils.allGroups()) {
        if (!group.contains(current)) continue;
        for (final p in group) {
          if (p != current &&
              candidates[p.row][p.col].contains(n) &&
              !path.contains(p)) {
            if (!peers.contains(p)) peers.add(p);
          }
        }
      }

      for (final next in peers) {
        if (next == start && path.length >= 4) {
          final elim = <CellPosition, Set<int>>{start: {n}};
          if (TechniqueUtils.verifyWithDlx(grid, candidates, {}, elim)) {
            return TechniqueResult(
              type: TechniqueType.biDirectionalXCycle,
              description:
                  '数字 $n 形成X链循环（弱链闭合），可从 R${start.row + 1}C${start.col + 1} 删除 $n',
              highlightCells: path,
              eliminateCandidates: elim,
              targetNumber: n,
            );
          }
        }
        final result = _dfsXCycle(
          n, start, next, false, [...path, next],
          conjugates, candidates, grid, depth + 1);
        if (result != null) return result;
      }
    } else {
      // Strong link (conjugate)
      for (final next in conjugates[current] ?? <CellPosition>[]) {
        if (next == start && path.length >= 4) {
          final place = <CellPosition, int>{start: n};
          if (TechniqueUtils.verifyWithDlx(
              grid, candidates, place, {})) {
            return TechniqueResult(
              type: TechniqueType.biDirectionalXCycle,
              description:
                  '数字 $n 形成X链循环（强链闭合），R${start.row + 1}C${start.col + 1} 必须填 $n',
              highlightCells: path,
              placements: place,
              targetNumber: n,
            );
          }
        }
        if (path.contains(next)) continue;
        final result = _dfsXCycle(
          n, start, next, true, [...path, next],
          conjugates, candidates, grid, depth + 1);
        if (result != null) return result;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Bidirectional Cycle (双向链 / AIC)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findBiDirectionalCycle(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (candidates[r][c].length != 2) continue;
        final start = CellPosition(r, c);
        final cands = candidates[r][c].toList();

        for (final startDigit in cands) {
          final result = _dfsAIC(
            startDigit, start, start, startDigit, true,
            [start], candidates, grid, 0);
          if (result != null) return result;
        }
      }
    }
    return null;
  }

  static TechniqueResult? _dfsAIC(
    int currentDigit,
    CellPosition start,
    CellPosition current,
    int startDigit,
    bool lastWasStrong,
    List<CellPosition> path,
    List<List<Set<int>>> candidates,
    List<List<int>> grid,
    int depth,
  ) {
    if (depth > 14) return null;

    if (lastWasStrong) {
      // Weak link: same digit, peer cell
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (!candidates[r][c].contains(currentDigit)) continue;
          final next = CellPosition(r, c);
          if (!TechniqueUtils.sees(current, next) || next == current) continue;
          if (path.contains(next)) continue;

          if (path.length >= 3 && currentDigit == startDigit) {
            final elim = <CellPosition, Set<int>>{};
            for (int rr = 0; rr < 9; rr++) {
              for (int cc = 0; cc < 9; cc++) {
                if (!candidates[rr][cc].contains(currentDigit)) continue;
                final p = CellPosition(rr, cc);
                if (path.contains(p) || p == next) continue;
                if (TechniqueUtils.sees(p, start) &&
                    TechniqueUtils.sees(p, next)) {
                  elim[p] = {currentDigit};
                }
              }
            }
            if (elim.isNotEmpty &&
                TechniqueUtils.verifyWithDlx(grid, candidates, {}, elim)) {
              return TechniqueResult(
                type: TechniqueType.biDirectionalCycle,
                description:
                    '交替推理链(AIC)：可从链两端的共同可见格中删除 $currentDigit',
                highlightCells: [...path, next],
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: currentDigit,
              );
            }
          }

          final result = _dfsAIC(
            currentDigit, start, next, startDigit, false,
            [...path, next], candidates, grid, depth + 1);
          if (result != null) return result;
        }
      }
    } else {
      // Strong link options:
      // 1. Same cell, different digit (bivalue cell)
      if (candidates[current.row][current.col].length == 2) {
        final otherDigit = candidates[current.row][current.col]
            .firstWhere((d) => d != currentDigit, orElse: () => 0);
        if (otherDigit != 0) {
          final result = _dfsAIC(
            otherDigit, start, current, startDigit, true,
            path, candidates, grid, depth + 1);
          if (result != null) return result;
        }
      }
      // 2. Same digit, conjugate pair in a group
      for (final group in TechniqueUtils.allGroups()) {
        if (!group.contains(current)) continue;
        final cells = group
            .where((p) => candidates[p.row][p.col].contains(currentDigit))
            .toList();
        if (cells.length == 2) {
          final next = cells[0] == current ? cells[1] : cells[0];
          if (path.contains(next)) continue;
          final result = _dfsAIC(
            currentDigit, start, next, startDigit, true,
            [...path, next], candidates, grid, depth + 1);
          if (result != null) return result;
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Cell Forcing Chain (单元格强制链组)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findCellForcingChain(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cands = candidates[r][c];
        if (cands.length < 2 || cands.length > 3) continue;

        final results = <int, Map<CellPosition, int>>{};
        for (final n in cands) {
          results[n] = TechniqueUtils.propagate(grid, candidates, r, c, n);
        }

        // Find common placements
        if (results.values.any((m) => m.isEmpty)) continue;
        final commonCells = results.values.first.keys.toSet();
        for (final m in results.values.skip(1)) {
          commonCells.retainAll(m.keys);
        }

        for (final cell in commonCells) {
          final values = results.values.map((m) => m[cell]).toSet();
          if (values.length == 1 && values.first != null) {
            final val = values.first!;
            if (grid[cell.row][cell.col] == 0 &&
                candidates[cell.row][cell.col].contains(val)) {
              return TechniqueResult(
                type: TechniqueType.cellForcingChain,
                description:
                    '从 R${r + 1}C${c + 1} 出发的强制链：无论该格填什么，'
                    'R${cell.row + 1}C${cell.col + 1} 都必须是 $val',
                highlightCells: [CellPosition(r, c), cell],
                placements: {cell: val},
                targetNumber: val,
              );
            }
          }
        }

        // Find common eliminations
        final elimResults = <int, Map<CellPosition, Set<int>>>{};
        for (final n in cands) {
          elimResults[n] = TechniqueUtils.propagateEliminations(
              grid, candidates, r, c, n);
        }
        final commonElimCells = elimResults.values.first.keys.toSet();
        for (final m in elimResults.values.skip(1)) {
          commonElimCells.retainAll(m.keys);
        }
        for (final cell in commonElimCells) {
          final common = elimResults.values.first[cell]!.toSet();
          for (final m in elimResults.values.skip(1)) {
            common.retainAll(m[cell] ?? {});
          }
          if (common.isNotEmpty &&
              candidates[cell.row][cell.col]
                  .intersection(common)
                  .isNotEmpty) {
            return TechniqueResult(
              type: TechniqueType.cellForcingChain,
              description:
                  '从 R${r + 1}C${c + 1} 出发的强制链：无论该格填什么，'
                  'R${cell.row + 1}C${cell.col + 1} 都不可能是 ${common.join(",")}',
              highlightCells: [CellPosition(r, c)],
              relatedCells: [cell],
              eliminateCandidates: {
                cell: common.intersection(candidates[cell.row][cell.col])
              },
            );
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Region Forcing Chain (区域强制链组)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findRegionForcingChain(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int n = 1; n <= 9; n++) {
      for (final group in TechniqueUtils.allGroups()) {
        final positions = group
            .where((p) => candidates[p.row][p.col].contains(n))
            .toList();
        if (positions.length < 2 || positions.length > 3) continue;

        final results = <CellPosition, Map<CellPosition, int>>{};
        for (final pos in positions) {
          results[pos] = TechniqueUtils.propagate(
              grid, candidates, pos.row, pos.col, n);
        }

        if (results.values.any((m) => m.isEmpty)) continue;
        final commonCells = results.values.first.keys.toSet();
        for (final m in results.values.skip(1)) {
          commonCells.retainAll(m.keys);
        }

        for (final cell in commonCells) {
          final values = results.values.map((m) => m[cell]).toSet();
          if (values.length == 1 && values.first != null) {
            final val = values.first!;
            if (grid[cell.row][cell.col] == 0 &&
                candidates[cell.row][cell.col].contains(val)) {
              return TechniqueResult(
                type: TechniqueType.regionForcingChain,
                description:
                    '区域强制链：数字 $n 在某组的所有可能位置出发，'
                    '都推导出 R${cell.row + 1}C${cell.col + 1} = $val',
                highlightCells: positions,
                relatedCells: [cell],
                placements: {cell: val},
                targetNumber: val,
              );
            }
          }
        }
      }
    }
    return null;
  }
}
