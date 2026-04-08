import '../models/technique.dart';

/// Core engine that detects applicable solving techniques on a given board.
///
/// Each detection method returns a [TechniqueResult] with full visualization
/// data, or `null` if the technique doesn't apply.
class TechniqueFinder {
  /// Find the simplest applicable technique on the current board.
  /// Techniques are tried in priority order (easiest first).
  static TechniqueResult? findNext(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    final finders = <TechniqueResult? Function()>[
      // Beginner
      () => _findBoxHiddenSingle(grid, candidates),
      () => _findRowHiddenSingle(grid, candidates),
      () => _findColHiddenSingle(grid, candidates),
      () => _findBoxElimination(grid, candidates),
      () => _findRowElimination(grid, candidates),
      () => _findColElimination(grid, candidates),
      // Intermediate
      () => _findNakedSingle(grid, candidates),
      () => _findExplicitPointing(grid, candidates),
      () => _findNakedPair(grid, candidates),
      () => _findHiddenPointing(grid, candidates),
      () => _findLineBoxClaiming(grid, candidates),
      // Advanced
      () => _findNakedTriple(grid, candidates),
      () => _findXWing(grid, candidates),
      () => _findHiddenPair(grid, candidates),
      () => _findHiddenTriple(grid, candidates),
      () => _findSwordfish(grid, candidates),
      () => _findSkyscraper(grid, candidates),
      () => _findXYWing(grid, candidates),
      () => _findStrongLinks2(grid, candidates),
      () => _findXYZWing(grid, candidates),
      // Expert
      () => _findStrongLinks3(grid, candidates),
      () => _findBUG1(grid, candidates),
      () => _findBUG2(grid, candidates),
      () => _findVWXYZWing(grid, candidates),
      () => _findUVWXYZWing(grid, candidates),
      // Chains
      () => _findBiDirectionalXCycle(grid, candidates),
      () => _findBiDirectionalCycle(grid, candidates),
      () => _findCellForcingChain(grid, candidates),
      () => _findRegionForcingChain(grid, candidates),
    ];

    for (final finder in finders) {
      final result = finder();
      if (result != null) return result;
    }
    return null;
  }

  /// Find a specific technique application.
  static TechniqueResult? findSpecific(
    TechniqueType type,
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    switch (type) {
      case TechniqueType.boxHiddenSingle:
        return _findBoxHiddenSingle(grid, candidates);
      case TechniqueType.rowHiddenSingle:
        return _findRowHiddenSingle(grid, candidates);
      case TechniqueType.colHiddenSingle:
        return _findColHiddenSingle(grid, candidates);
      case TechniqueType.boxElimination:
        return _findBoxElimination(grid, candidates);
      case TechniqueType.rowElimination:
        return _findRowElimination(grid, candidates);
      case TechniqueType.colElimination:
        return _findColElimination(grid, candidates);
      case TechniqueType.nakedSingle:
        return _findNakedSingle(grid, candidates);
      case TechniqueType.explicitBoxLineReduction:
        return _findExplicitPointing(grid, candidates);
      case TechniqueType.nakedPair:
        return _findNakedPair(grid, candidates);
      case TechniqueType.hiddenBoxLineReduction:
        return _findHiddenPointing(grid, candidates);
      case TechniqueType.lineBoxClaiming:
        return _findLineBoxClaiming(grid, candidates);
      case TechniqueType.nakedTriple:
        return _findNakedTriple(grid, candidates);
      case TechniqueType.xWing:
        return _findXWing(grid, candidates);
      case TechniqueType.hiddenPair:
        return _findHiddenPair(grid, candidates);
      case TechniqueType.explicitNakedTriple:
        return _findNakedTriple(grid, candidates);
      case TechniqueType.hiddenTriple:
        return _findHiddenTriple(grid, candidates);
      case TechniqueType.swordfish:
        return _findSwordfish(grid, candidates);
      case TechniqueType.skyscraper:
        return _findSkyscraper(grid, candidates);
      case TechniqueType.xyWing:
        return _findXYWing(grid, candidates);
      case TechniqueType.strongLinks2:
        return _findStrongLinks2(grid, candidates);
      case TechniqueType.xyzWing:
        return _findXYZWing(grid, candidates);
      case TechniqueType.strongLinks3:
        return _findStrongLinks3(grid, candidates);
      case TechniqueType.bug1:
        return _findBUG1(grid, candidates);
      case TechniqueType.bug2:
        return _findBUG2(grid, candidates);
      case TechniqueType.vwxyzWing:
        return _findVWXYZWing(grid, candidates);
      case TechniqueType.uvwxyzWing:
        return _findUVWXYZWing(grid, candidates);
      case TechniqueType.biDirectionalXCycle:
        return _findBiDirectionalXCycle(grid, candidates);
      case TechniqueType.biDirectionalCycle:
        return _findBiDirectionalCycle(grid, candidates);
      case TechniqueType.cellForcingChain:
        return _findCellForcingChain(grid, candidates);
      case TechniqueType.regionForcingChain:
        return _findRegionForcingChain(grid, candidates);
    }
  }

  // ---------------------------------------------------------------------------
  // Utility
  // ---------------------------------------------------------------------------

  static Set<int> _computeCandidates(List<List<int>> grid, int r, int c) {
    final used = <int>{};
    for (int i = 0; i < 9; i++) {
      used.add(grid[r][i]);
      used.add(grid[i][c]);
    }
    final br = (r ~/ 3) * 3, bc = (c ~/ 3) * 3;
    for (int dr = 0; dr < 3; dr++) {
      for (int dc = 0; dc < 3; dc++) {
        used.add(grid[br + dr][bc + dc]);
      }
    }
    return {for (int n = 1; n <= 9; n++) if (!used.contains(n)) n};
  }

  /// Compute candidates for the entire grid.
  static List<List<Set<int>>> computeAllCandidates(List<List<int>> grid) {
    return List.generate(
      9,
      (r) => List.generate(
        9,
        (c) => grid[r][c] == 0 ? _computeCandidates(grid, r, c) : <int>{},
      ),
    );
  }

  static List<CellPosition> _boxCells(int boxRow, int boxCol) {
    return [
      for (int r = boxRow; r < boxRow + 3; r++)
        for (int c = boxCol; c < boxCol + 3; c++) CellPosition(r, c),
    ];
  }

  static List<CellPosition> _rowCells(int row) {
    return [for (int c = 0; c < 9; c++) CellPosition(row, c)];
  }

  static List<CellPosition> _colCells(int col) {
    return [for (int r = 0; r < 9; r++) CellPosition(r, col)];
  }

  // ---------------------------------------------------------------------------
  // Beginner: Box Hidden Single (宫唯一数)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findBoxHiddenSingle(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int br = 0; br < 9; br += 3) {
      for (int bc = 0; bc < 9; bc += 3) {
        for (int n = 1; n <= 9; n++) {
          final positions = <CellPosition>[];
          for (int r = br; r < br + 3; r++) {
            for (int c = bc; c < bc + 3; c++) {
              if (candidates[r][c].contains(n)) positions.add(CellPosition(r, c));
            }
          }
          if (positions.length == 1) {
            final pos = positions[0];
            final boxCells = _boxCells(br, bc)
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
  // Beginner: Row Hidden Single (行唯一数)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findRowHiddenSingle(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int r = 0; r < 9; r++) {
      for (int n = 1; n <= 9; n++) {
        final positions = <CellPosition>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) positions.add(CellPosition(r, c));
        }
        if (positions.length == 1) {
          final pos = positions[0];
          final rowCells = _rowCells(r)
              .where((p) => p.col != pos.col)
              .toList();
          return TechniqueResult(
            type: TechniqueType.rowHiddenSingle,
            description: '在第${r + 1}行中，数字 $n 只能放在 R${pos.row + 1}C${pos.col + 1}',
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
  // Beginner: Column Hidden Single (列唯一数)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findColHiddenSingle(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int c = 0; c < 9; c++) {
      for (int n = 1; n <= 9; n++) {
        final positions = <CellPosition>[];
        for (int r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) positions.add(CellPosition(r, c));
        }
        if (positions.length == 1) {
          final pos = positions[0];
          final colCells = _colCells(c)
              .where((p) => p.row != pos.row)
              .toList();
          return TechniqueResult(
            type: TechniqueType.colHiddenSingle,
            description: '在第${c + 1}列中，数字 $n 只能放在 R${pos.row + 1}C${pos.col + 1}',
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
  // Beginner: Box Elimination (宫摒除法)
  // A digit in a box is restricted to one row/col, eliminating from that
  // row/col outside the box.
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findBoxElimination(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int br = 0; br < 9; br += 3) {
      for (int bc = 0; bc < 9; bc += 3) {
        for (int n = 1; n <= 9; n++) {
          final positions = <CellPosition>[];
          for (int r = br; r < br + 3; r++) {
            for (int c = bc; c < bc + 3; c++) {
              if (candidates[r][c].contains(n)) positions.add(CellPosition(r, c));
            }
          }
          if (positions.length < 2) continue;

          // All in same row? → eliminate from that row outside this box
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

          // All in same col? → eliminate from that col outside this box
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
  // Beginner: Row Elimination (行摒除法)
  // A digit in a row is restricted to one box, eliminating from that box
  // outside the row.
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findRowElimination(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int r = 0; r < 9; r++) {
      for (int n = 1; n <= 9; n++) {
        final positions = <CellPosition>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) positions.add(CellPosition(r, c));
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
  // Beginner: Column Elimination (列摒除法)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findColElimination(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int c = 0; c < 9; c++) {
      for (int n = 1; n <= 9; n++) {
        final positions = <CellPosition>[];
        for (int r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) positions.add(CellPosition(r, c));
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

  // ---------------------------------------------------------------------------
  // Intermediate: Naked Single (唯一余数)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findNakedSingle(
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
  // Intermediate: Explicit Pointing (宫对行列区块摒除法 - 显性)
  // Same logic as boxElimination but presented as pointing pair/triple.
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findExplicitPointing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // Already covered by boxElimination, but re-check with emphasis on
    // pointing pairs/triples specifically where count == 2 or 3.
    for (int br = 0; br < 9; br += 3) {
      for (int bc = 0; bc < 9; bc += 3) {
        for (int n = 1; n <= 9; n++) {
          final positions = <CellPosition>[];
          for (int r = br; r < br + 3; r++) {
            for (int c = bc; c < bc + 3; c++) {
              if (candidates[r][c].contains(n)) positions.add(CellPosition(r, c));
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
  // Intermediate: Naked Pair (直观2数对)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findNakedPair(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (final group in _allGroups()) {
      final cells = group.where((p) => candidates[p.row][p.col].length == 2).toList();
      for (int i = 0; i < cells.length; i++) {
        for (int j = i + 1; j < cells.length; j++) {
          final c1 = candidates[cells[i].row][cells[i].col];
          final c2 = candidates[cells[j].row][cells[j].col];
          if (c1.length == 2 && c1.containsAll(c2) && c2.containsAll(c1)) {
            final pair = c1;
            final elim = <CellPosition, Set<int>>{};
            for (final p in group) {
              if (p != cells[i] && p != cells[j]) {
                final toRemove = candidates[p.row][p.col].intersection(pair);
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
  // Intermediate: Hidden Pointing (宫对行列区块摒除法 - 隐性)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findHiddenPointing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // In a box, if a candidate appears only in cells that share a row/col,
    // AND those cells have other candidates, it's a hidden pointing.
    for (int br = 0; br < 9; br += 3) {
      for (int bc = 0; bc < 9; bc += 3) {
        for (int n = 1; n <= 9; n++) {
          final positions = <CellPosition>[];
          for (int r = br; r < br + 3; r++) {
            for (int c = bc; c < bc + 3; c++) {
              if (candidates[r][c].contains(n)) positions.add(CellPosition(r, c));
            }
          }
          if (positions.length < 2 || positions.length > 3) continue;
          // Only count as hidden if at least one cell has other candidates
          final hasOthers = positions.any((p) => candidates[p.row][p.col].length > 1);
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
  // Intermediate: Line→Box Claiming (行列对宫区块摒除法 - 隐性)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findLineBoxClaiming(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // Row claiming: digit in row confined to one box → remove from box outside row
    for (int r = 0; r < 9; r++) {
      for (int n = 1; n <= 9; n++) {
        final positions = <CellPosition>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) positions.add(CellPosition(r, c));
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
          if (candidates[r][c].contains(n)) positions.add(CellPosition(r, c));
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

  // ---------------------------------------------------------------------------
  // Advanced: Naked Triple (直观3数对 / 显性3数对)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findNakedTriple(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (final group in _allGroups()) {
      final cells = group
          .where((p) =>
              candidates[p.row][p.col].length >= 2 &&
              candidates[p.row][p.col].length <= 3)
          .toList();
      for (int i = 0; i < cells.length; i++) {
        for (int j = i + 1; j < cells.length; j++) {
          for (int k = j + 1; k < cells.length; k++) {
            final union = <int>{
              ...candidates[cells[i].row][cells[i].col],
              ...candidates[cells[j].row][cells[j].col],
              ...candidates[cells[k].row][cells[k].col],
            };
            if (union.length == 3) {
              final elim = <CellPosition, Set<int>>{};
              for (final p in group) {
                if (p != cells[i] && p != cells[j] && p != cells[k]) {
                  final toRemove = candidates[p.row][p.col].intersection(union);
                  if (toRemove.isNotEmpty) {
                    elim[p] = toRemove;
                  }
                }
              }
              if (elim.isNotEmpty) {
                return TechniqueResult(
                  type: TechniqueType.nakedTriple,
                  description:
                      'R${cells[i].row + 1}C${cells[i].col + 1}、R${cells[j].row + 1}C${cells[j].col + 1}、'
                      'R${cells[k].row + 1}C${cells[k].col + 1} 形成三数组 {${union.join(",")}}，'
                      '可从同组其他格中删除这些数字',
                  highlightCells: [cells[i], cells[j], cells[k]],
                  relatedCells: elim.keys.toList(),
                  eliminateCandidates: elim,
                );
              }
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Advanced: X-Wing
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findXWing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // Row-based
    for (int n = 1; n <= 9; n++) {
      for (int r1 = 0; r1 < 9; r1++) {
        final cols1 = <int>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r1][c].contains(n)) cols1.add(c);
        }
        if (cols1.length != 2) continue;
        for (int r2 = r1 + 1; r2 < 9; r2++) {
          final cols2 = <int>[];
          for (int c = 0; c < 9; c++) {
            if (candidates[r2][c].contains(n)) cols2.add(c);
          }
          if (cols2.length == 2 && cols2[0] == cols1[0] && cols2[1] == cols1[1]) {
            final elim = <CellPosition, Set<int>>{};
            for (int r = 0; r < 9; r++) {
              if (r != r1 && r != r2) {
                if (candidates[r][cols1[0]].contains(n)) {
                  elim[CellPosition(r, cols1[0])] = {n};
                }
                if (candidates[r][cols1[1]].contains(n)) {
                  elim[CellPosition(r, cols1[1])] = {n};
                }
              }
            }
            if (elim.isNotEmpty) {
              final corners = [
                CellPosition(r1, cols1[0]),
                CellPosition(r1, cols1[1]),
                CellPosition(r2, cols1[0]),
                CellPosition(r2, cols1[1]),
              ];
              return TechniqueResult(
                type: TechniqueType.xWing,
                description:
                    '数字 $n 在第${r1 + 1}行和第${r2 + 1}行各只出现在第${cols1[0] + 1}、${cols1[1] + 1}列，'
                    '形成 X-Wing，可从这两列的其他行中删除 $n',
                highlightCells: corners,
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: n,
                lines: [
                  HighlightLine(corners[0], corners[3], style: HighlightLineStyle.arrow, digit: n),
                  HighlightLine(corners[1], corners[2], style: HighlightLineStyle.arrow, digit: n),
                ],
              );
            }
          }
        }
      }
      // Col-based
      for (int c1 = 0; c1 < 9; c1++) {
        final rows1 = <int>[];
        for (int r = 0; r < 9; r++) {
          if (candidates[r][c1].contains(n)) rows1.add(r);
        }
        if (rows1.length != 2) continue;
        for (int c2 = c1 + 1; c2 < 9; c2++) {
          final rows2 = <int>[];
          for (int r = 0; r < 9; r++) {
            if (candidates[r][c2].contains(n)) rows2.add(r);
          }
          if (rows2.length == 2 && rows2[0] == rows1[0] && rows2[1] == rows1[1]) {
            final elim = <CellPosition, Set<int>>{};
            for (int c = 0; c < 9; c++) {
              if (c != c1 && c != c2) {
                if (candidates[rows1[0]][c].contains(n)) {
                  elim[CellPosition(rows1[0], c)] = {n};
                }
                if (candidates[rows1[1]][c].contains(n)) {
                  elim[CellPosition(rows1[1], c)] = {n};
                }
              }
            }
            if (elim.isNotEmpty) {
              final corners = [
                CellPosition(rows1[0], c1),
                CellPosition(rows1[0], c2),
                CellPosition(rows1[1], c1),
                CellPosition(rows1[1], c2),
              ];
              return TechniqueResult(
                type: TechniqueType.xWing,
                description:
                    '数字 $n 在第${c1 + 1}列和第${c2 + 1}列各只出现在第${rows1[0] + 1}、${rows1[1] + 1}行，'
                    '形成 X-Wing，可从这两行的其他列中删除 $n',
                highlightCells: corners,
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: n,
                lines: [
                  HighlightLine(corners[0], corners[3], style: HighlightLineStyle.arrow, digit: n),
                  HighlightLine(corners[1], corners[2], style: HighlightLineStyle.arrow, digit: n),
                ],
              );
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Advanced: Hidden Pair (隐性2数对)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findHiddenPair(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (final group in _allGroups()) {
      for (int n1 = 1; n1 <= 9; n1++) {
        for (int n2 = n1 + 1; n2 <= 9; n2++) {
          final pos1 = <CellPosition>[];
          final pos2 = <CellPosition>[];
          for (final p in group) {
            if (candidates[p.row][p.col].contains(n1)) pos1.add(p);
            if (candidates[p.row][p.col].contains(n2)) pos2.add(p);
          }
          if (pos1.length == 2 && pos2.length == 2 &&
              pos1[0] == pos2[0] && pos1[1] == pos2[1]) {
            final keep = {n1, n2};
            final elim = <CellPosition, Set<int>>{};
            for (final p in [pos1[0], pos1[1]]) {
              final toRemove = candidates[p.row][p.col].difference(keep);
              if (toRemove.isNotEmpty) {
                elim[p] = toRemove;
              }
            }
            if (elim.isNotEmpty) {
              return TechniqueResult(
                type: TechniqueType.hiddenPair,
                description:
                    '数字 $n1 和 $n2 在同组中只出现在 R${pos1[0].row + 1}C${pos1[0].col + 1} '
                    '和 R${pos1[1].row + 1}C${pos1[1].col + 1}，形成隐性数对，'
                    '可删除这两格中的其他候选数',
                highlightCells: [pos1[0], pos1[1]],
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
  // Advanced: Hidden Triple (隐性3数对)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findHiddenTriple(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (final group in _allGroups()) {
      for (int n1 = 1; n1 <= 9; n1++) {
        for (int n2 = n1 + 1; n2 <= 9; n2++) {
          for (int n3 = n2 + 1; n3 <= 9; n3++) {
            final posUnion = <CellPosition>{};
            for (final p in group) {
              final cands = candidates[p.row][p.col];
              if (cands.contains(n1) || cands.contains(n2) || cands.contains(n3)) {
                posUnion.add(p);
              }
            }
            if (posUnion.length == 3) {
              // Verify each digit appears in at least one of these 3 cells
              final cells = posUnion.toList();
              bool allPresent = true;
              for (final n in [n1, n2, n3]) {
                if (!cells.any((p) => candidates[p.row][p.col].contains(n))) {
                  allPresent = false;
                  break;
                }
              }
              if (!allPresent) continue;

              final keep = {n1, n2, n3};
              final elim = <CellPosition, Set<int>>{};
              for (final p in cells) {
                final toRemove = candidates[p.row][p.col].difference(keep);
                if (toRemove.isNotEmpty) {
                  elim[p] = toRemove;
                }
              }
              if (elim.isNotEmpty) {
                return TechniqueResult(
                  type: TechniqueType.hiddenTriple,
                  description:
                      '数字 $n1、$n2、$n3 在同组中只出现在 3 个格中，形成隐性三数组，'
                      '可删除这些格中的其他候选数',
                  highlightCells: cells,
                  eliminateCandidates: elim,
                );
              }
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Advanced: Swordfish (剑鱼)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findSwordfish(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // Row-based Swordfish
    for (int n = 1; n <= 9; n++) {
      final rowCols = <int, List<int>>{};
      for (int r = 0; r < 9; r++) {
        final cols = <int>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) cols.add(c);
        }
        if (cols.length >= 2 && cols.length <= 3) rowCols[r] = cols;
      }
      final rows = rowCols.keys.toList();
      for (int i = 0; i < rows.length; i++) {
        for (int j = i + 1; j < rows.length; j++) {
          for (int k = j + 1; k < rows.length; k++) {
            final colUnion = <int>{
              ...rowCols[rows[i]]!,
              ...rowCols[rows[j]]!,
              ...rowCols[rows[k]]!,
            };
            if (colUnion.length == 3) {
              final elim = <CellPosition, Set<int>>{};
              for (final c in colUnion) {
                for (int r = 0; r < 9; r++) {
                  if (r != rows[i] && r != rows[j] && r != rows[k]) {
                    if (candidates[r][c].contains(n)) {
                      elim[CellPosition(r, c)] = {n};
                    }
                  }
                }
              }
              if (elim.isNotEmpty) {
                final highlights = <CellPosition>[];
                for (final r in [rows[i], rows[j], rows[k]]) {
                  for (final c in rowCols[r]!) {
                    highlights.add(CellPosition(r, c));
                  }
                }
                return TechniqueResult(
                  type: TechniqueType.swordfish,
                  description:
                      '数字 $n 在第${rows[i] + 1}、${rows[j] + 1}、${rows[k] + 1}行形成 Swordfish，'
                      '可从第${colUnion.map((c) => c + 1).join("、")}列的其他行中删除 $n',
                  highlightCells: highlights,
                  relatedCells: elim.keys.toList(),
                  eliminateCandidates: elim,
                  targetNumber: n,
                );
              }
            }
          }
        }
      }

      // Col-based Swordfish
      final colRows = <int, List<int>>{};
      for (int c = 0; c < 9; c++) {
        final rows2 = <int>[];
        for (int r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) rows2.add(r);
        }
        if (rows2.length >= 2 && rows2.length <= 3) colRows[c] = rows2;
      }
      final cols = colRows.keys.toList();
      for (int i = 0; i < cols.length; i++) {
        for (int j = i + 1; j < cols.length; j++) {
          for (int k = j + 1; k < cols.length; k++) {
            final rowUnion = <int>{
              ...colRows[cols[i]]!,
              ...colRows[cols[j]]!,
              ...colRows[cols[k]]!,
            };
            if (rowUnion.length == 3) {
              final elim = <CellPosition, Set<int>>{};
              for (final r in rowUnion) {
                for (int c = 0; c < 9; c++) {
                  if (c != cols[i] && c != cols[j] && c != cols[k]) {
                    if (candidates[r][c].contains(n)) {
                      elim[CellPosition(r, c)] = {n};
                    }
                  }
                }
              }
              if (elim.isNotEmpty) {
                final highlights = <CellPosition>[];
                for (final c in [cols[i], cols[j], cols[k]]) {
                  for (final r in colRows[c]!) {
                    highlights.add(CellPosition(r, c));
                  }
                }
                return TechniqueResult(
                  type: TechniqueType.swordfish,
                  description:
                      '数字 $n 在第${cols[i] + 1}、${cols[j] + 1}、${cols[k] + 1}列形成 Swordfish，'
                      '可从第${rowUnion.map((r) => r + 1).join("、")}行的其他列中删除 $n',
                  highlightCells: highlights,
                  relatedCells: elim.keys.toList(),
                  eliminateCandidates: elim,
                  targetNumber: n,
                );
              }
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Advanced: Skyscraper (摩天楼)
  // Two rows with exactly 2 positions for a digit, sharing one column.
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findSkyscraper(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int n = 1; n <= 9; n++) {
      // Row-based skyscraper
      final rowPositions = <int, List<int>>{};
      for (int r = 0; r < 9; r++) {
        final cols = <int>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) cols.add(c);
        }
        if (cols.length == 2) rowPositions[r] = cols;
      }
      final rows = rowPositions.keys.toList();
      for (int i = 0; i < rows.length; i++) {
        for (int j = i + 1; j < rows.length; j++) {
          final c1 = rowPositions[rows[i]]!;
          final c2 = rowPositions[rows[j]]!;
          // Share exactly one column (the "base")
          for (int ci = 0; ci < 2; ci++) {
            for (int cj = 0; cj < 2; cj++) {
              if (c1[ci] == c2[cj]) {
                final topCol = c1[1 - ci];
                final bottomCol = c2[1 - cj];
                if (topCol == bottomCol) continue;
                // Eliminate from cells that see both "top" endpoints
                final elim = <CellPosition, Set<int>>{};
                for (int r = 0; r < 9; r++) {
                  for (int c = 0; c < 9; c++) {
                    if (!candidates[r][c].contains(n)) continue;
                    if (r == rows[i] && c == topCol) continue;
                    if (r == rows[j] && c == bottomCol) continue;
                    final seesTop = (r == rows[i] || c == topCol ||
                        ((r ~/ 3) == (rows[i] ~/ 3) && (c ~/ 3) == (topCol ~/ 3)));
                    final seesBottom = (r == rows[j] || c == bottomCol ||
                        ((r ~/ 3) == (rows[j] ~/ 3) && (c ~/ 3) == (bottomCol ~/ 3)));
                    if (seesTop && seesBottom) {
                      elim[CellPosition(r, c)] = {n};
                    }
                  }
                }
                if (elim.isNotEmpty) {
                  return TechniqueResult(
                    type: TechniqueType.skyscraper,
                    description:
                        '数字 $n 在第${rows[i] + 1}行和第${rows[j] + 1}行形成摩天楼结构，'
                        '可删除能同时看到两个端点的格的候选数 $n',
                    highlightCells: [
                      CellPosition(rows[i], c1[0]),
                      CellPosition(rows[i], c1[1]),
                      CellPosition(rows[j], c2[0]),
                      CellPosition(rows[j], c2[1]),
                    ],
                    relatedCells: elim.keys.toList(),
                    eliminateCandidates: elim,
                    targetNumber: n,
                    lines: [
                      HighlightLine(
                        CellPosition(rows[i], c1[ci]),
                        CellPosition(rows[j], c2[cj]),
                        style: HighlightLineStyle.arrow,
                        digit: n,
                      ),
                    ],
                  );
                }
              }
            }
          }
        }
      }

      // Col-based skyscraper
      final colPositions = <int, List<int>>{};
      for (int c = 0; c < 9; c++) {
        final rowList = <int>[];
        for (int r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) rowList.add(r);
        }
        if (rowList.length == 2) colPositions[c] = rowList;
      }
      final colKeys = colPositions.keys.toList();
      for (int i = 0; i < colKeys.length; i++) {
        for (int j = i + 1; j < colKeys.length; j++) {
          final r1 = colPositions[colKeys[i]]!;
          final r2 = colPositions[colKeys[j]]!;
          for (int ri = 0; ri < 2; ri++) {
            for (int rj = 0; rj < 2; rj++) {
              if (r1[ri] == r2[rj]) {
                final topRow = r1[1 - ri];
                final bottomRow = r2[1 - rj];
                if (topRow == bottomRow) continue;
                final elim = <CellPosition, Set<int>>{};
                for (int r = 0; r < 9; r++) {
                  for (int c = 0; c < 9; c++) {
                    if (!candidates[r][c].contains(n)) continue;
                    if (r == topRow && c == colKeys[i]) continue;
                    if (r == bottomRow && c == colKeys[j]) continue;
                    final seesTop = (r == topRow || c == colKeys[i] ||
                        ((r ~/ 3) == (topRow ~/ 3) && (c ~/ 3) == (colKeys[i] ~/ 3)));
                    final seesBottom = (r == bottomRow || c == colKeys[j] ||
                        ((r ~/ 3) == (bottomRow ~/ 3) && (c ~/ 3) == (colKeys[j] ~/ 3)));
                    if (seesTop && seesBottom) {
                      elim[CellPosition(r, c)] = {n};
                    }
                  }
                }
                if (elim.isNotEmpty) {
                  return TechniqueResult(
                    type: TechniqueType.skyscraper,
                    description:
                        '数字 $n 在第${colKeys[i] + 1}列和第${colKeys[j] + 1}列形成摩天楼结构，'
                        '可删除能同时看到两个端点的格的候选数 $n',
                    highlightCells: [
                      CellPosition(r1[0], colKeys[i]),
                      CellPosition(r1[1], colKeys[i]),
                      CellPosition(r2[0], colKeys[j]),
                      CellPosition(r2[1], colKeys[j]),
                    ],
                    relatedCells: elim.keys.toList(),
                    eliminateCandidates: elim,
                    targetNumber: n,
                    lines: [
                      HighlightLine(
                        CellPosition(r1[ri], colKeys[i]),
                        CellPosition(r2[rj], colKeys[j]),
                        style: HighlightLineStyle.arrow,
                        digit: n,
                      ),
                    ],
                  );
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Advanced: XY-Wing
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findXYWing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (candidates[r][c].length != 2) continue;
        final pivot = CellPosition(r, c);
        final pivotCands = candidates[r][c].toList();
        final a = pivotCands[0], b = pivotCands[1];

        final peers = _peers(r, c);
        final wing1Candidates = <CellPosition>[];
        final wing2Candidates = <CellPosition>[];

        for (final peer in peers) {
          final pc = candidates[peer.row][peer.col];
          if (pc.length != 2) continue;
          if (pc.contains(a) && !pc.contains(b)) wing1Candidates.add(peer);
          if (pc.contains(b) && !pc.contains(a)) wing2Candidates.add(peer);
        }

        for (final w1 in wing1Candidates) {
          final w1c = candidates[w1.row][w1.col];
          final cValue = w1c.firstWhere((x) => x != a);
          for (final w2 in wing2Candidates) {
            final w2c = candidates[w2.row][w2.col];
            if (!w2c.contains(cValue)) continue;
            final cCheck = w2c.firstWhere((x) => x != b);
            if (cCheck != cValue) continue;

            // w1 and w2 must NOT be peers of each other is not required
            // Eliminate cValue from cells that see BOTH w1 and w2
            final elim = <CellPosition, Set<int>>{};
            for (int rr = 0; rr < 9; rr++) {
              for (int cc = 0; cc < 9; cc++) {
                if (!candidates[rr][cc].contains(cValue)) continue;
                final p = CellPosition(rr, cc);
                if (p == pivot || p == w1 || p == w2) continue;
                if (_sees(p, w1) && _sees(p, w2)) {
                  elim[p] = {cValue};
                }
              }
            }
            if (elim.isNotEmpty) {
              return TechniqueResult(
                type: TechniqueType.xyWing,
                description:
                    'R${r + 1}C${c + 1}{$a,$b} 为中心，'
                    'R${w1.row + 1}C${w1.col + 1}{$a,$cValue} 和 '
                    'R${w2.row + 1}C${w2.col + 1}{$b,$cValue} 为翼，'
                    '形成 XY-Wing，可从能看到两翼的格中删除 $cValue',
                highlightCells: [pivot, w1, w2],
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: cValue,
                lines: [
                  HighlightLine(pivot, w1, style: HighlightLineStyle.arrow, digit: a),
                  HighlightLine(pivot, w2, style: HighlightLineStyle.arrow, digit: b),
                ],
              );
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Advanced: Strong Links (2-string kite)
  // A row strong link and a column strong link share one cell.
  // Cells that see BOTH non-shared endpoints can have n eliminated.
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findStrongLinks2(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int n = 1; n <= 9; n++) {
      for (int r = 0; r < 9; r++) {
        final rowCols = <int>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) rowCols.add(c);
        }
        if (rowCols.length != 2) continue;

        for (int c = 0; c < 9; c++) {
          final colRows = <int>[];
          for (int rr = 0; rr < 9; rr++) {
            if (candidates[rr][c].contains(n)) colRows.add(rr);
          }
          if (colRows.length != 2) continue;

          for (int ri = 0; ri < 2; ri++) {
            for (int ci = 0; ci < 2; ci++) {
              if (rowCols[ri] == c && colRows[ci] == r) {
                // Shared cell: (r, c)
                // Non-shared endpoints:
                final endA = CellPosition(r, rowCols[1 - ri]); // row endpoint
                final endB = CellPosition(colRows[1 - ci], c); // col endpoint

                // Eliminate from cells that see BOTH endpoints AND the shared cell
                final shared = CellPosition(r, c);
                final elim = <CellPosition, Set<int>>{};
                for (int rr = 0; rr < 9; rr++) {
                  for (int cc = 0; cc < 9; cc++) {
                    if (!candidates[rr][cc].contains(n)) continue;
                    final p = CellPosition(rr, cc);
                    if (p == endA || p == endB || p == shared) continue;
                    if (_sees(p, endA) && _sees(p, endB) && _sees(p, shared)) {
                      elim[p] = {n};
                    }
                  }
                }

                if (elim.isNotEmpty) {
                  return TechniqueResult(
                    type: TechniqueType.strongLinks2,
                    description:
                        '数字 $n 在第${r + 1}行和第${c + 1}列形成强链（2数组），'
                        '可从${elim.keys.map((p) => "R${p.row + 1}C${p.col + 1}").join("、")}删除 $n',
                    highlightCells: [endA, endB, CellPosition(r, c)],
                    relatedCells: elim.keys.toList(),
                    eliminateCandidates: elim,
                    targetNumber: n,
                    lines: [
                      HighlightLine(CellPosition(r, rowCols[0]), CellPosition(r, rowCols[1]), style: HighlightLineStyle.arrow, digit: n),
                      HighlightLine(CellPosition(colRows[0], c), CellPosition(colRows[1], c), style: HighlightLineStyle.arrow, digit: n),
                    ],
                  );
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Advanced: XYZ-Wing
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findXYZWing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (candidates[r][c].length != 3) continue;
        final pivot = CellPosition(r, c);
        final pivotCands = candidates[r][c].toList();

        final peers = _peers(r, c);
        final biValuePeers = peers
            .where((p) => candidates[p.row][p.col].length == 2)
            .toList();

        for (int i = 0; i < biValuePeers.length; i++) {
          for (int j = i + 1; j < biValuePeers.length; j++) {
            final w1 = biValuePeers[i], w2 = biValuePeers[j];
            final w1c = candidates[w1.row][w1.col];
            final w2c = candidates[w2.row][w2.col];

            // Both wings must be subsets of pivot
            if (!candidates[r][c].containsAll(w1c)) continue;
            if (!candidates[r][c].containsAll(w2c)) continue;

            // Union of wings must equal pivot
            final wingUnion = {...w1c, ...w2c};
            if (wingUnion.length != 3) continue;
            if (!wingUnion.containsAll(pivotCands)) continue;

            // The common digit z
            final common = w1c.intersection(w2c);
            if (common.length != 1) continue;
            final z = common.first;

            // Eliminate z from cells that see all three
            final elim = <CellPosition, Set<int>>{};
            for (int rr = 0; rr < 9; rr++) {
              for (int cc = 0; cc < 9; cc++) {
                if (!candidates[rr][cc].contains(z)) continue;
                final p = CellPosition(rr, cc);
                if (p == pivot || p == w1 || p == w2) continue;
                if (_sees(p, pivot) && _sees(p, w1) && _sees(p, w2)) {
                  elim[p] = {z};
                }
              }
            }
            if (elim.isNotEmpty) {
              return TechniqueResult(
                type: TechniqueType.xyzWing,
                description:
                    'R${r + 1}C${c + 1}{${pivotCands.join(",")}} 为中心，'
                    '与两翼形成 XYZ-Wing，'
                    '可从能看到三格的位置删除 $z',
                highlightCells: [pivot, w1, w2],
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: z,
                lines: [
                  HighlightLine(pivot, w1, style: HighlightLineStyle.arrow, digit: z),
                  HighlightLine(pivot, w2, style: HighlightLineStyle.arrow, digit: z),
                ],
              );
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Expert: Strong Links 3 (强链3数组)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findStrongLinks3(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // Simple coloring: find conjugate pairs for a digit, color them,
    // and look for eliminations.
    for (int n = 1; n <= 9; n++) {
      final conjugates = <CellPosition, List<CellPosition>>{};
      // Build conjugate graph
      for (final group in _allGroups()) {
        final cells = group.where((p) => candidates[p.row][p.col].contains(n)).toList();
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

        // Rule 1: Two same-color cells in same group → that color is false
        final color0 = queue.where((p) => color[p] == 0).toList();
        final color1 = queue.where((p) => color[p] == 1).toList();

        int? falseColor;
        for (final group in _allGroups()) {
          final g0 = color0.where((p) => group.contains(p)).toList();
          final g1 = color1.where((p) => group.contains(p)).toList();
          if (g0.length > 1) { falseColor = 0; break; }
          if (g1.length > 1) { falseColor = 1; break; }
        }

        if (falseColor != null) {
          final trueColor = 1 - falseColor;
          final trueCells = queue.where((p) => color[p] == trueColor).toList();
          final falseCells = queue.where((p) => color[p] == falseColor).toList();
          if (trueCells.length >= 2) {
            final elim = <CellPosition, Set<int>>{};
            for (final p in falseCells) {
              elim[p] = {n};
            }
            if (elim.isNotEmpty) {
              return TechniqueResult(
                type: TechniqueType.strongLinks3,
                description: '数字 $n 的着色推理：同色格冲突，可确定另一色为真，删除假色候选数',
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
            final seesColor0 = color0.any((cp) => _sees(p, cp));
            final seesColor1 = color1.any((cp) => _sees(p, cp));
            if (seesColor0 && seesColor1) {
              elim[p] = {n};
            }
          }
        }
        if (elim.isNotEmpty) {
          return TechniqueResult(
            type: TechniqueType.strongLinks3,
            description: '数字 $n 的强链着色：某格同时看到两种颜色，可删除该格的候选数 $n',
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
  // Expert: BUG1 (二向值坟墓 Type 1)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findBUG1(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // BUG: all unsolved cells have exactly 2 candidates, except one with 3.
    CellPosition? triCell;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] != 0) continue;
        final len = candidates[r][c].length;
        if (len == 2) continue;
        if (len == 3 && triCell == null) {
          triCell = CellPosition(r, c);
        } else {
          return null; // More than one non-bivalue cell
        }
      }
    }
    if (triCell == null) return null;

    // The digit that appears 3 times in a row/col/box through triCell is the answer
    final cands = candidates[triCell.row][triCell.col].toList();
    for (final n in cands) {
      // Count appearances of n in triCell's row, col, box among candidates
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
      // In a BUG state, one count should be odd (3 instead of 2)
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
  // Expert: BUG2 (二向值坟墓 Type 2)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findBUG2(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // BUG+1 variant: all cells bivalue except two cells with 3 candidates,
    // sharing the extra digit and in the same group.
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

    // Find the extra digit (appears 3 times in some unit)
    final c1 = candidates[triCells[0].row][triCells[0].col];
    final c2 = candidates[triCells[1].row][triCells[1].col];
    // Both should share a common "extra" digit
    final common = c1.intersection(c2);
    if (common.isEmpty) return null;

    if (!_sees(triCells[0], triCells[1])) return null;

    for (final n in common) {
      // Check if n has odd occurrence count in shared groups
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
        // Eliminate n from cells that see both tri-cells
        final elim = <CellPosition, Set<int>>{};
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (!candidates[r][c].contains(n)) continue;
            final p = CellPosition(r, c);
            if (p == triCells[0] || p == triCells[1]) continue;
            if (_sees(p, triCells[0]) && _sees(p, triCells[1])) {
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
  // Expert: VWXYZ-Wing / UVWXYZ-Wing (larger wings)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findVWXYZWing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    return _findLargeWing(grid, candidates, 5, TechniqueType.vwxyzWing, 'VWXYZ-Wing');
  }

  static TechniqueResult? _findUVWXYZWing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    return _findLargeWing(grid, candidates, 6, TechniqueType.uvwxyzWing, 'UVWXYZ-Wing');
  }

  static TechniqueResult? _findLargeWing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
    int wingSize,
    TechniqueType type,
    String name,
  ) {
    // Generalized ALS-XZ approach for larger wings.
    // Pivot cell has (wingSize-1) candidates, each wing has 2 candidates.
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final pivotCands = candidates[r][c];
        if (pivotCands.length != wingSize - 1 && pivotCands.length != wingSize) continue;
        if (pivotCands.isEmpty) continue;
        final pivot = CellPosition(r, c);
        final peers = _peers(r, c)
            .where((p) => candidates[p.row][p.col].length == 2 &&
                candidates[p.row][p.col].intersection(pivotCands).isNotEmpty)
            .toList();

        if (peers.length < wingSize - 1) continue;

        // Try combinations of (wingSize-1) wings
        final combos = _combinations(peers, wingSize - 1);
        for (final combo in combos) {
          final allCands = <int>{...pivotCands};
          for (final w in combo) {
            allCands.addAll(candidates[w.row][w.col]);
          }
          if (allCands.length != wingSize) continue;

          // Find the common digit z that appears in all wings
          Set<int> commonInWings = Set.from(candidates[combo[0].row][combo[0].col]);
          for (int i = 1; i < combo.length; i++) {
            commonInWings = commonInWings.intersection(candidates[combo[i].row][combo[i].col]);
          }
          // z must also be in pivot
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
                if (allCells.every((cp) => _sees(p, cp))) {
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

  // ---------------------------------------------------------------------------
  // Chains: Bidirectional X-Cycle (双向X链)
  // Uses DLX to verify any chain conclusion before returning.
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findBiDirectionalXCycle(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int n = 1; n <= 9; n++) {
      final conjugates = <CellPosition, List<CellPosition>>{};
      for (final group in _allGroups()) {
        final cells = group.where((p) => candidates[p.row][p.col].contains(n)).toList();
        if (cells.length == 2) {
          conjugates.putIfAbsent(cells[0], () => []).add(cells[1]);
          conjugates.putIfAbsent(cells[1], () => []).add(cells[0]);
        }
      }
      if (conjugates.length < 4) continue;

      for (final start in conjugates.keys) {
        final result = _dfsXCycle(n, start, start, true, [start], conjugates, candidates, grid, 0);
        if (result != null) return result;
      }
    }
    return null;
  }

  /// Verify a proposed elimination/placement using DLX.
  /// Returns true if the elimination is consistent with the unique solution.
  static bool _verifyWithDlx(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
    Map<CellPosition, int> placements,
    Map<CellPosition, Set<int>> eliminations,
  ) {
    // Solve the puzzle to get the unique solution
    final solGrid = List.generate(9, (r) => List<int>.from(grid[r]));
    if (!_dlxSolve(solGrid)) return false;

    // Check placements
    for (final entry in placements.entries) {
      if (solGrid[entry.key.row][entry.key.col] != entry.value) return false;
    }
    // Check eliminations don't remove solution values
    for (final entry in eliminations.entries) {
      if (entry.value.contains(solGrid[entry.key.row][entry.key.col])) return false;
    }
    return true;
  }

  /// Simple DLX solve wrapper (avoids import cycle by inlining minimal solve).
  static bool _dlxSolve(List<List<int>> grid) {
    // Use backtracking with MRV — fast enough for verification
    final pos = _findBestEmptyForVerify(grid);
    if (pos == null) return true;
    final (row, col) = pos;
    for (int num = 1; num <= 9; num++) {
      if (_isValidPlacement(grid, row, col, num)) {
        grid[row][col] = num;
        if (_dlxSolve(grid)) return true;
        grid[row][col] = 0;
      }
    }
    return false;
  }

  static (int, int)? _findBestEmptyForVerify(List<List<int>> grid) {
    int bestCount = 10;
    (int, int)? best;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] != 0) continue;
        int n = 0;
        for (int v = 1; v <= 9; v++) {
          if (_isValidPlacement(grid, r, c, v)) n++;
        }
        if (n == 0) return (r, c);
        if (n < bestCount) { bestCount = n; best = (r, c); if (n == 1) return best; }
      }
    }
    return best;
  }

  static bool _isValidPlacement(List<List<int>> grid, int row, int col, int num) {
    for (int c = 0; c < 9; c++) if (grid[row][c] == num) return false;
    for (int r = 0; r < 9; r++) if (grid[r][col] == num) return false;
    final br = (row ~/ 3) * 3, bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        if (grid[r][c] == num) return false;
      }
    }
    return true;
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
      // Next: weak link (any peer with candidate n, NOT a conjugate in the same group)
      final peers = <CellPosition>[];
      for (final group in _allGroups()) {
        if (!group.contains(current)) continue;
        for (final p in group) {
          if (p != current && candidates[p.row][p.col].contains(n) && !path.contains(p)) {
            if (!peers.contains(p)) peers.add(p);
          }
        }
      }

      for (final next in peers) {
        if (next == start && path.length >= 4) {
          // Type 2: weak link closes the cycle → eliminate n from start
          final elim = <CellPosition, Set<int>>{start: {n}};
          if (_verifyWithDlx(grid, candidates, {}, elim)) {
            return TechniqueResult(
              type: TechniqueType.biDirectionalXCycle,
              description: '数字 $n 形成X链循环（弱链闭合），可从 R${start.row + 1}C${start.col + 1} 删除 $n',
              highlightCells: path,
              eliminateCandidates: elim,
              targetNumber: n,
            );
          }
        }
        final result = _dfsXCycle(n, start, next, false, [...path, next], conjugates, candidates, grid, depth + 1);
        if (result != null) return result;
      }
    } else {
      // Next: strong link (conjugate)
      for (final next in conjugates[current] ?? <CellPosition>[]) {
        if (next == start && path.length >= 4) {
          // Type 1: strong link closes the cycle → start must be n
          final place = <CellPosition, int>{start: n};
          if (_verifyWithDlx(grid, candidates, place, {})) {
            return TechniqueResult(
              type: TechniqueType.biDirectionalXCycle,
              description: '数字 $n 形成X链循环（强链闭合），R${start.row + 1}C${start.col + 1} 必须填 $n',
              highlightCells: path,
              placements: place,
              targetNumber: n,
            );
          }
        }
        if (path.contains(next)) continue;
        final result = _dfsXCycle(n, start, next, true, [...path, next], conjugates, candidates, grid, depth + 1);
        if (result != null) return result;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Chains: Bidirectional Cycle (双向链)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findBiDirectionalCycle(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // AIC: Alternating Inference Chain using multiple digits.
    // Simplified: look for short chains (length <= 6) with strong/weak links.
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (candidates[r][c].length != 2) continue;
        final start = CellPosition(r, c);
        final cands = candidates[r][c].toList();

        for (final startDigit in cands) {
          final result = _dfsAIC(startDigit, start, start, startDigit, true, [start], candidates, grid, 0);
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
          if (!_sees(current, next) || next == current) continue;
          if (path.contains(next)) continue;

          // Check if this weak link endpoint can produce an AIC elimination
          if (path.length >= 3 && currentDigit == startDigit) {
            final elim = <CellPosition, Set<int>>{};
            for (int rr = 0; rr < 9; rr++) {
              for (int cc = 0; cc < 9; cc++) {
                if (!candidates[rr][cc].contains(currentDigit)) continue;
                final p = CellPosition(rr, cc);
                if (path.contains(p) || p == next) continue;
                if (_sees(p, start) && _sees(p, next)) {
                  elim[p] = {currentDigit};
                }
              }
            }
            if (elim.isNotEmpty && _verifyWithDlx(grid, candidates, {}, elim)) {
              return TechniqueResult(
                type: TechniqueType.biDirectionalCycle,
                description: '交替推理链(AIC)：可从链两端的共同可见格中删除 $currentDigit',
                highlightCells: [...path, next],
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: currentDigit,
              );
            }
          }

          final result = _dfsAIC(currentDigit, start, next, startDigit, false, [...path, next], candidates, grid, depth + 1);
          if (result != null) return result;
        }
      }
    } else {
      // Strong link options:
      // 1. Same cell, different digit (bivalue cell)
      if (candidates[current.row][current.col].length == 2) {
        final otherDigit = candidates[current.row][current.col].firstWhere((d) => d != currentDigit, orElse: () => 0);
        if (otherDigit != 0) {
          final result = _dfsAIC(otherDigit, start, current, startDigit, true, path, candidates, grid, depth + 1);
          if (result != null) return result;
        }
      }
      // 2. Same digit, conjugate pair in a group
      for (final group in _allGroups()) {
        if (!group.contains(current)) continue;
        final cells = group.where((p) => candidates[p.row][p.col].contains(currentDigit)).toList();
        if (cells.length == 2) {
          final next = cells[0] == current ? cells[1] : cells[0];
          if (path.contains(next)) continue;
          final result = _dfsAIC(currentDigit, start, next, startDigit, true, [...path, next], candidates, grid, depth + 1);
          if (result != null) return result;
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Chains: Cell Forcing Chain (单元格强制链组)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findCellForcingChain(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // For each cell with 2-3 candidates, assume each candidate and propagate.
    // If all assumptions lead to the same conclusion, that conclusion is true.
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cands = candidates[r][c];
        if (cands.length < 2 || cands.length > 3) continue;

        // For each candidate, propagate singles and see what we can determine
        final results = <int, Map<CellPosition, int>>{};
        for (final n in cands) {
          results[n] = _propagate(grid, candidates, r, c, n);
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
            if (grid[cell.row][cell.col] == 0 && candidates[cell.row][cell.col].contains(val)) {
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
          elimResults[n] = _propagateEliminations(grid, candidates, r, c, n);
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
          if (common.isNotEmpty && candidates[cell.row][cell.col].intersection(common).isNotEmpty) {
            return TechniqueResult(
              type: TechniqueType.cellForcingChain,
              description:
                  '从 R${r + 1}C${c + 1} 出发的强制链：无论该格填什么，'
                  'R${cell.row + 1}C${cell.col + 1} 都不可能是 ${common.join(",")}',
              highlightCells: [CellPosition(r, c)],
              relatedCells: [cell],
              eliminateCandidates: {cell: common.intersection(candidates[cell.row][cell.col])},
            );
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Chains: Region Forcing Chain (区域强制链组)
  // ---------------------------------------------------------------------------

  static TechniqueResult? _findRegionForcingChain(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // For each digit n in each group, if n has 2-3 positions,
    // assume n at each position and propagate.
    for (int n = 1; n <= 9; n++) {
      for (final group in _allGroups()) {
        final positions = group.where((p) => candidates[p.row][p.col].contains(n)).toList();
        if (positions.length < 2 || positions.length > 3) continue;

        final results = <CellPosition, Map<CellPosition, int>>{};
        for (final pos in positions) {
          results[pos] = _propagate(grid, candidates, pos.row, pos.col, n);
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
            if (grid[cell.row][cell.col] == 0 && candidates[cell.row][cell.col].contains(val)) {
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

  // ---------------------------------------------------------------------------
  // Propagation helpers for forcing chains
  // ---------------------------------------------------------------------------

  static Map<CellPosition, int> _propagate(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
    int startRow,
    int startCol,
    int startVal,
  ) {
    final g = List.generate(9, (r) => List<int>.from(grid[r]));
    final c = List.generate(
      9,
      (r) => List.generate(9, (col) => Set<int>.from(candidates[r][col])),
    );
    final placed = <CellPosition, int>{};

    g[startRow][startCol] = startVal;
    c[startRow][startCol].clear();
    _eliminateFromGrid(c, startRow, startCol, startVal);
    placed[CellPosition(startRow, startCol)] = startVal;

    bool progress = true;
    int iterations = 0;
    while (progress && iterations < 50) {
      progress = false;
      iterations++;
      for (int r = 0; r < 9; r++) {
        for (int col = 0; col < 9; col++) {
          if (g[r][col] == 0 && c[r][col].length == 1) {
            final val = c[r][col].first;
            g[r][col] = val;
            c[r][col].clear();
            _eliminateFromGrid(c, r, col, val);
            placed[CellPosition(r, col)] = val;
            progress = true;
          }
        }
      }
    }
    return placed;
  }

  static Map<CellPosition, Set<int>> _propagateEliminations(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
    int startRow,
    int startCol,
    int startVal,
  ) {
    final c = List.generate(
      9,
      (r) => List.generate(9, (col) => Set<int>.from(candidates[r][col])),
    );
    final originalCands = List.generate(
      9,
      (r) => List.generate(9, (col) => Set<int>.from(candidates[r][col])),
    );

    c[startRow][startCol] = {startVal};
    _eliminateFromGrid(c, startRow, startCol, startVal);

    bool progress = true;
    int iterations = 0;
    while (progress && iterations < 50) {
      progress = false;
      iterations++;
      for (int r = 0; r < 9; r++) {
        for (int col = 0; col < 9; col++) {
          if (c[r][col].length == 1 && originalCands[r][col].length > 1) {
            final val = c[r][col].first;
            _eliminateFromGrid(c, r, col, val);
            progress = true;
          }
        }
      }
    }

    final elims = <CellPosition, Set<int>>{};
    for (int r = 0; r < 9; r++) {
      for (int col = 0; col < 9; col++) {
        final removed = originalCands[r][col].difference(c[r][col]);
        if (removed.isNotEmpty) {
          elims[CellPosition(r, col)] = removed;
        }
      }
    }
    return elims;
  }

  static void _eliminateFromGrid(List<List<Set<int>>> cands, int row, int col, int val) {
    for (int i = 0; i < 9; i++) {
      cands[row][i].remove(val);
      cands[i][col].remove(val);
    }
    final br = (row ~/ 3) * 3, bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        cands[r][c].remove(val);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  static List<List<CellPosition>> _allGroups() {
    final groups = <List<CellPosition>>[];
    for (int r = 0; r < 9; r++) {
      groups.add(_rowCells(r));
    }
    for (int c = 0; c < 9; c++) {
      groups.add(_colCells(c));
    }
    for (int br = 0; br < 9; br += 3) {
      for (int bc = 0; bc < 9; bc += 3) {
        groups.add(_boxCells(br, bc));
      }
    }
    return groups;
  }

  static bool _sees(CellPosition a, CellPosition b) {
    if (a.row == b.row) return true;
    if (a.col == b.col) return true;
    if ((a.row ~/ 3) == (b.row ~/ 3) && (a.col ~/ 3) == (b.col ~/ 3)) return true;
    return false;
  }

  static List<CellPosition> _peers(int row, int col) {
    final result = <CellPosition>{};
    for (int c = 0; c < 9; c++) {
      if (c != col) result.add(CellPosition(row, c));
    }
    for (int r = 0; r < 9; r++) {
      if (r != row) result.add(CellPosition(r, col));
    }
    final br = (row ~/ 3) * 3, bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        if (r != row || c != col) result.add(CellPosition(r, c));
      }
    }
    return result.toList();
  }

  static List<List<CellPosition>> _combinations(List<CellPosition> items, int k) {
    final result = <List<CellPosition>>[];
    void combine(int start, List<CellPosition> current) {
      if (current.length == k) {
        result.add(List.from(current));
        return;
      }
      for (int i = start; i < items.length; i++) {
        current.add(items[i]);
        combine(i + 1, current);
        current.removeLast();
      }
    }
    combine(0, []);
    return result;
  }
}
