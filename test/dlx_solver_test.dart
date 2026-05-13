import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/services/dlx_solver.dart';

void main() {
  group('DlxSolver.solve', () {
    test('solves a standard puzzle', () {
      final grid = [
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
      final original = List.generate(9, (r) => List<int>.from(grid[r]));

      final solved = DlxSolver.solve(grid);

      expect(solved, isTrue);
      // Every row must contain 1-9
      for (int r = 0; r < 9; r++) {
        expect(grid[r].toSet(), equals({1, 2, 3, 4, 5, 6, 7, 8, 9}));
      }
      // Every column must contain 1-9
      for (int c = 0; c < 9; c++) {
        final col = List.generate(9, (r) => grid[r][c]);
        expect(col.toSet(), equals({1, 2, 3, 4, 5, 6, 7, 8, 9}));
      }
      // Original clues preserved
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (original[r][c] != 0) {
            expect(grid[r][c], original[r][c]);
          }
        }
      }
    });

    test('returns false for unsolvable puzzle', () {
      final grid = [
        [1, 1, 0, 0, 0, 0, 0, 0, 0], // duplicate in row
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];
      final solved = DlxSolver.solve(grid);
      expect(solved, isFalse);
    });

    test('solves an empty grid', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      final solved = DlxSolver.solve(grid);
      expect(solved, isTrue);
      for (int r = 0; r < 9; r++) {
        expect(grid[r].toSet(), equals({1, 2, 3, 4, 5, 6, 7, 8, 9}));
      }
    });
  });

  group('DlxSolver.countSolutions', () {
    test('counts exactly 1 for a proper puzzle', () {
      final grid = [
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
      final count = DlxSolver.countSolutions(grid);
      expect(count, 1);
    });

    test('detects multiple solutions in sparse grid', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][0] = 1;
      grid[8][8] = 9;
      final count = DlxSolver.countSolutions(grid, limit: 3);
      expect(count, greaterThanOrEqualTo(2));
    });

    test('returns 0 for unsolvable puzzle', () {
      final grid = [
        [1, 2, 3, 4, 5, 6, 7, 8, 9],
        [2, 0, 0, 0, 0, 0, 0, 0, 0], // 2 conflicts with row 1 col 0
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];
      final count = DlxSolver.countSolutions(grid);
      expect(count, 0);
    });
  });

  group('DlxSolver.solveRandom', () {
    test('produces a valid solution', () {
      final grid = [
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
      final solved = DlxSolver.solveRandom(grid, Random(42));

      expect(solved, isTrue);
      for (int r = 0; r < 9; r++) {
        expect(grid[r].toSet(), equals({1, 2, 3, 4, 5, 6, 7, 8, 9}));
      }
    });

    test('different seeds may produce different solutions', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      final grid2 = List.generate(9, (_) => List.filled(9, 0));

      DlxSolver.solveRandom(grid, Random(1));
      DlxSolver.solveRandom(grid2, Random(2));

      // Both should be valid solutions (may or may not differ)
      for (int r = 0; r < 9; r++) {
        expect(grid[r].toSet(), equals({1, 2, 3, 4, 5, 6, 7, 8, 9}));
        expect(grid2[r].toSet(), equals({1, 2, 3, 4, 5, 6, 7, 8, 9}));
      }
    });
  });
}
