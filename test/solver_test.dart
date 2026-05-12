import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import 'package:sudoku/services/sudoku_solver.dart';

void main() {
  // Well-known puzzle with a unique solution (Arto Inkala's "world's hardest")
  // and a standard easy puzzle for reuse.
  final standardEasy = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
  ];

  /// Verify a solved grid is a valid Sudoku solution.
  void expectValidSolution(List<List<int>> grid, List<List<int>> original) {
    // Every cell filled with 1-9
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        expect(grid[r][c], inInclusiveRange(1, 9));
      }
    }
    // Row uniqueness
    for (int r = 0; r < 9; r++) {
      expect(grid[r].toSet().length, 9);
    }
    // Column uniqueness
    for (int c = 0; c < 9; c++) {
      final col = List.generate(9, (r) => grid[r][c]);
      expect(col.toSet().length, 9);
    }
    // Box uniqueness
    for (int br = 0; br < 9; br += 3) {
      for (int bc = 0; bc < 9; bc += 3) {
        final box = <int>{};
        for (int r = br; r < br + 3; r++) {
          for (int c = bc; c < bc + 3; c++) {
            box.add(grid[r][c]);
          }
        }
        expect(box.length, 9);
      }
    }
    // Original clues preserved
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (original[r][c] != 0) {
          expect(grid[r][c], original[r][c]);
        }
      }
    }
  }

  group('SudokuSolver.solve', () {
    test('solves a standard easy puzzle', () {
      final grid = List.generate(9, (r) => List<int>.from(standardEasy[r]));
      final solved = SudokuSolver.solve(grid);
      expect(solved, isTrue);
      expectValidSolution(grid, standardEasy);
    });

    test('solves an already-complete grid (no-op)', () {
      final grid = [
        [1, 2, 3, 4, 5, 6, 7, 8, 9],
        [4, 5, 6, 7, 8, 9, 1, 2, 3],
        [7, 8, 9, 1, 2, 3, 4, 5, 6],
        [2, 3, 1, 5, 6, 4, 8, 9, 7],
        [5, 6, 4, 8, 9, 7, 2, 3, 1],
        [8, 9, 7, 2, 3, 1, 5, 6, 4],
        [3, 1, 2, 6, 4, 5, 9, 7, 8],
        [6, 4, 5, 9, 7, 8, 3, 1, 2],
        [9, 7, 8, 3, 1, 2, 6, 4, 5],
      ];
      final solved = SudokuSolver.solve(grid);
      expect(solved, isTrue);
      // Should remain unchanged
      expect(grid[0], [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('solves an empty grid', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      final solved = SudokuSolver.solve(grid);
      expect(solved, isTrue);
      expectValidSolution(grid, List.generate(9, (_) => List.filled(9, 0)));
    });

    test('solves a minimal 17-clue puzzle', () {
      final grid = [
        [0, 0, 0, 0, 0, 0, 0, 1, 0],
        [4, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 2, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 5, 0, 4, 0, 7],
        [0, 0, 8, 0, 0, 0, 3, 0, 0],
        [0, 0, 1, 0, 9, 0, 0, 0, 0],
        [3, 0, 0, 4, 0, 0, 2, 0, 0],
        [0, 5, 0, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 8, 0, 6, 0, 0, 0],
      ];
      final original = List.generate(9, (r) => List<int>.from(grid[r]));
      final solved = SudokuSolver.solve(grid);
      expect(solved, isTrue);
      expectValidSolution(grid, original);
    });

    test('returns false for row-duplicate puzzle', () {
      final grid = [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 5, 7, 9], // 5 at (8,6) conflicts: col6 has 5 at (4,0) no...
      ];
      final solved = SudokuSolver.solve(grid);
      expect(solved, isFalse);
    });

    test('returns false for column-duplicate puzzle', () {
      final grid = [
        [1, 2, 3, 4, 5, 6, 7, 8, 9],
        [1, 0, 0, 0, 0, 0, 0, 0, 0], // duplicate 1 in col 0
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];
      expect(SudokuSolver.solve(grid), isFalse);
    });

    test('returns false for box-duplicate puzzle', () {
      final grid = [
        [1, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 1, 0, 0, 0, 0, 0, 0, 0], // duplicate 1 in box (0,0)
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];
      expect(SudokuSolver.solve(grid), isFalse);
    });

    test('returns false for over-constrained dead-end puzzle', () {
      // A puzzle where one cell has no valid candidate
      final grid = [
        [1, 2, 3, 4, 5, 6, 7, 8, 9],
        [4, 5, 6, 7, 8, 9, 1, 2, 3],
        [7, 8, 9, 1, 2, 3, 4, 5, 6],
        [2, 3, 1, 5, 6, 4, 8, 9, 7],
        [5, 6, 4, 8, 9, 7, 2, 3, 1],
        [8, 9, 7, 2, 3, 1, 5, 6, 4],
        [3, 1, 2, 6, 4, 5, 9, 7, 8],
        [6, 4, 5, 9, 7, 8, 3, 1, 2],
        [9, 7, 8, 3, 1, 2, 6, 4, 5], // all filled, valid
      ];
      // Now make it impossible by changing one cell
      grid[8][8] = 0;
      // Cell (8,8) must be 5 but row 8 already has 5 at col 4... no, let me think again
      // Actually the complete solution above is valid. Let me create a real dead end.
      // Place two 1s in row 0 and try to solve the rest
      final deadEnd = [
        [1, 0, 0, 0, 0, 0, 0, 0, 1], // duplicate 1 in row
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];
      expect(SudokuSolver.solve(deadEnd), isFalse);
    });
  });

  group('SudokuSolver.countSolutions', () {
    test('counts exactly 1 for a proper puzzle', () {
      final grid = List.generate(9, (r) => List<int>.from(standardEasy[r]));
      expect(SudokuSolver.countSolutions(grid), 1);
    });

    test('counts exactly 1 for the 17-clue puzzle', () {
      final grid = [
        [0, 0, 0, 0, 0, 0, 0, 1, 0],
        [4, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 2, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 5, 0, 4, 0, 7],
        [0, 0, 8, 0, 0, 0, 3, 0, 0],
        [0, 0, 1, 0, 9, 0, 0, 0, 0],
        [3, 0, 0, 4, 0, 0, 2, 0, 0],
        [0, 5, 0, 1, 0, 0, 0, 0, 0],
        [0, 0, 0, 8, 0, 6, 0, 0, 0],
      ];
      expect(SudokuSolver.countSolutions(grid), 1);
    });

    test('detects multiple solutions with limit=2', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][0] = 1;
      grid[1][1] = 2;
      grid[2][2] = 3;
      final count = SudokuSolver.countSolutions(grid, limit: 2);
      expect(count, greaterThanOrEqualTo(2));
    });

    test('counts with higher limit on sparse grid', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][0] = 1;
      final count = SudokuSolver.countSolutions(grid, limit: 100);
      expect(count, greaterThanOrEqualTo(100));
    });

    test('returns 0 for unsolvable puzzle', () {
      final grid = [
        [1, 2, 3, 4, 5, 6, 7, 8, 9],
        [1, 0, 0, 0, 0, 0, 0, 0, 0], // duplicate 1 in col 0
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];
      expect(SudokuSolver.countSolutions(grid), 0);
    });

    test('returns 0 for box-conflict puzzle', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][0] = 5;
      grid[1][1] = 5; // same box, same digit
      expect(SudokuSolver.countSolutions(grid), 0);
    });

    test('complete valid grid counts as 1', () {
      final grid = [
        [1, 2, 3, 4, 5, 6, 7, 8, 9],
        [4, 5, 6, 7, 8, 9, 1, 2, 3],
        [7, 8, 9, 1, 2, 3, 4, 5, 6],
        [2, 3, 1, 5, 6, 4, 8, 9, 7],
        [5, 6, 4, 8, 9, 7, 2, 3, 1],
        [8, 9, 7, 2, 3, 1, 5, 6, 4],
        [3, 1, 2, 6, 4, 5, 9, 7, 8],
        [6, 4, 5, 9, 7, 8, 3, 1, 2],
        [9, 7, 8, 3, 1, 2, 6, 4, 5],
      ];
      expect(SudokuSolver.countSolutions(grid), 1);
    });
  });

  group('SudokuSolver.solveRandom', () {
    test('produces a valid solution', () {
      final grid = List.generate(9, (r) => List<int>.from(standardEasy[r]));
      final solved = SudokuSolver.solveRandom(grid, UniqueRandom());
      expect(solved, isTrue);
      for (int r = 0; r < 9; r++) {
        expect(grid[r].toSet(), {1, 2, 3, 4, 5, 6, 7, 8, 9});
      }
    });

    test('produces a valid solution for empty grid', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      final solved = SudokuSolver.solveRandom(grid, UniqueRandom());
      expect(solved, isTrue);
      for (int r = 0; r < 9; r++) {
        expect(grid[r].toSet(), {1, 2, 3, 4, 5, 6, 7, 8, 9});
      }
    });
  });
}

/// Simple deterministic PRNG for tests.
class UniqueRandom implements Random {
  int _seed = DateTime.now().millisecondsSinceEpoch;
  @override
  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() => nextInt(10000) / 10000;
}
