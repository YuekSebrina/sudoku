import '../../models/technique.dart';

/// Shared utilities used across all technique detection modules.
class TechniqueUtils {
  static Set<int> computeCandidates(List<List<int>> grid, int r, int c) {
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
        (c) => grid[r][c] == 0 ? computeCandidates(grid, r, c) : <int>{},
      ),
    );
  }

  static List<CellPosition> boxCells(int boxRow, int boxCol) {
    return [
      for (int r = boxRow; r < boxRow + 3; r++)
        for (int c = boxCol; c < boxCol + 3; c++) CellPosition(r, c),
    ];
  }

  static List<CellPosition> rowCells(int row) {
    return [for (int c = 0; c < 9; c++) CellPosition(row, c)];
  }

  static List<CellPosition> colCells(int col) {
    return [for (int r = 0; r < 9; r++) CellPosition(r, col)];
  }

  static List<List<CellPosition>> allGroups() {
    final groups = <List<CellPosition>>[];
    for (int r = 0; r < 9; r++) {
      groups.add(rowCells(r));
    }
    for (int c = 0; c < 9; c++) {
      groups.add(colCells(c));
    }
    for (int br = 0; br < 9; br += 3) {
      for (int bc = 0; bc < 9; bc += 3) {
        groups.add(boxCells(br, bc));
      }
    }
    return groups;
  }

  static bool sees(CellPosition a, CellPosition b) {
    if (a.row == b.row) return true;
    if (a.col == b.col) return true;
    if ((a.row ~/ 3) == (b.row ~/ 3) && (a.col ~/ 3) == (b.col ~/ 3)) {
      return true;
    }
    return false;
  }

  static List<CellPosition> peers(int row, int col) {
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

  static List<List<CellPosition>> combinations(
    List<CellPosition> items,
    int k,
  ) {
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

  static void eliminateFromGrid(
    List<List<Set<int>>> cands,
    int row,
    int col,
    int val,
  ) {
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

  /// Propagate singles from a starting placement. Returns placed cells.
  static Map<CellPosition, int> propagate(
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
    eliminateFromGrid(c, startRow, startCol, startVal);
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
            eliminateFromGrid(c, r, col, val);
            placed[CellPosition(r, col)] = val;
            progress = true;
          }
        }
      }
    }
    return placed;
  }

  /// Propagate eliminations from a starting placement. Returns eliminations.
  static Map<CellPosition, Set<int>> propagateEliminations(
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
    eliminateFromGrid(c, startRow, startCol, startVal);

    bool progress = true;
    int iterations = 0;
    while (progress && iterations < 50) {
      progress = false;
      iterations++;
      for (int r = 0; r < 9; r++) {
        for (int col = 0; col < 9; col++) {
          if (c[r][col].length == 1 && originalCands[r][col].length > 1) {
            final val = c[r][col].first;
            eliminateFromGrid(c, r, col, val);
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

  /// Verify a proposed elimination/placement using backtracking.
  /// Returns true if the elimination is consistent with the unique solution.
  static bool verifyWithDlx(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
    Map<CellPosition, int> placements,
    Map<CellPosition, Set<int>> eliminations,
  ) {
    final solGrid = List.generate(9, (r) => List<int>.from(grid[r]));
    if (!_dlxSolve(solGrid)) return false;

    for (final entry in placements.entries) {
      if (solGrid[entry.key.row][entry.key.col] != entry.value) return false;
    }
    for (final entry in eliminations.entries) {
      if (entry.value.contains(solGrid[entry.key.row][entry.key.col])) {
        return false;
      }
    }
    return true;
  }

  static bool _dlxSolve(List<List<int>> grid) {
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
        if (n < bestCount) {
          bestCount = n;
          best = (r, c);
          if (n == 1) return best;
        }
      }
    }
    return best;
  }

  static bool _isValidPlacement(
    List<List<int>> grid,
    int row,
    int col,
    int num,
  ) {
    for (int c = 0; c < 9; c++) {
      if (grid[row][c] == num) return false;
    }
    for (int r = 0; r < 9; r++) {
      if (grid[r][col] == num) return false;
    }
    final br = (row ~/ 3) * 3, bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        if (grid[r][c] == num) return false;
      }
    }
    return true;
  }
}
