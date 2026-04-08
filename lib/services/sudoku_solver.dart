import 'dart:math';

class SudokuSolver {
  /// Solves the puzzle in-place. Returns true if a solution exists.
  static bool solve(List<List<int>> grid) {
    final pos = _findBestEmpty(grid);
    if (pos == null) return true;

    final (row, col) = pos;
    for (int num = 1; num <= 9; num++) {
      if (_isValid(grid, row, col, num)) {
        grid[row][col] = num;
        if (solve(grid)) return true;
        grid[row][col] = 0;
      }
    }
    return false;
  }

  /// Solves with randomized candidate order (for generation).
  static bool solveRandom(List<List<int>> grid, Random random) {
    final pos = _findBestEmpty(grid);
    if (pos == null) return true;

    final (row, col) = pos;
    final nums = List.generate(9, (i) => i + 1)..shuffle(random);
    for (int num in nums) {
      if (_isValid(grid, row, col, num)) {
        grid[row][col] = num;
        if (solveRandom(grid, random)) return true;
        grid[row][col] = 0;
      }
    }
    return false;
  }

  /// Counts solutions up to [limit]. Used to verify unique solution.
  static int countSolutions(List<List<int>> grid, {int limit = 2}) {
    return _countHelper(grid, 0, limit);
  }

  static int _countHelper(List<List<int>> grid, int count, int limit) {
    if (count >= limit) return count;

    final pos = _findBestEmpty(grid);
    if (pos == null) return count + 1;

    final (row, col) = pos;
    for (int num = 1; num <= 9; num++) {
      if (_isValid(grid, row, col, num)) {
        grid[row][col] = num;
        count = _countHelper(grid, count, limit);
        grid[row][col] = 0;
        if (count >= limit) return count;
      }
    }
    return count;
  }

  /// MRV heuristic: pick the empty cell with fewest valid candidates.
  /// Dramatically reduces backtracking on sparse grids.
  static (int, int)? _findBestEmpty(List<List<int>> grid) {
    int bestCount = 10;
    (int, int)? best;

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] != 0) continue;
        int n = 0;
        for (int v = 1; v <= 9; v++) {
          if (_isValid(grid, r, c, v)) n++;
        }
        if (n == 0) return (r, c); // dead end, fail fast
        if (n < bestCount) {
          bestCount = n;
          best = (r, c);
          if (n == 1) return best; // only one choice, pick immediately
        }
      }
    }
    return best;
  }

  static bool _isValid(List<List<int>> grid, int row, int col, int num) {
    for (int c = 0; c < 9; c++) {
      if (grid[row][c] == num) return false;
    }
    for (int r = 0; r < 9; r++) {
      if (grid[r][col] == num) return false;
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (grid[r][c] == num) return false;
      }
    }
    return true;
  }
}
