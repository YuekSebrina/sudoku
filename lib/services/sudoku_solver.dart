import 'dart:math';

class SudokuSolver {
  /// Solves the puzzle in-place. Returns true if a solution exists.
  static bool solve(List<List<int>> grid) {
    final empty = _findEmpty(grid);
    if (empty == null) return true;

    final (row, col) = empty;
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
    final empty = _findEmpty(grid);
    if (empty == null) return true;

    final (row, col) = empty;
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
    return _countSolutionsHelper(grid, 0, limit);
  }

  static int _countSolutionsHelper(List<List<int>> grid, int count, int limit) {
    if (count >= limit) return count;

    final empty = _findEmpty(grid);
    if (empty == null) return count + 1;

    final (row, col) = empty;
    for (int num = 1; num <= 9; num++) {
      if (_isValid(grid, row, col, num)) {
        grid[row][col] = num;
        count = _countSolutionsHelper(grid, count, limit);
        grid[row][col] = 0;
        if (count >= limit) return count;
      }
    }
    return count;
  }

  static (int, int)? _findEmpty(List<List<int>> grid) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) return (r, c);
      }
    }
    return null;
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
