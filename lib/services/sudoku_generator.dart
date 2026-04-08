import 'dart:math';

import '../models/difficulty.dart';
import '../models/sudoku_board.dart';
import 'sudoku_solver.dart';

class SudokuGenerator {
  final Random _random;

  SudokuGenerator({int? seed}) : _random = Random(seed);

  /// Generates a new Sudoku puzzle with the given difficulty.
  /// Returns a record of (puzzle board, solution values).
  ({SudokuBoard puzzle, List<List<int>> solution}) generate(Difficulty difficulty) {
    final solution = _generateFullSolution();
    final puzzle = _digHoles(solution, difficulty.clues);
    return (
      puzzle: SudokuBoard.fromValues(puzzle),
      solution: solution,
    );
  }

  List<List<int>> _generateFullSolution() {
    final grid = List.generate(9, (_) => List.filled(9, 0));
    SudokuSolver.solveRandom(grid, _random);
    return grid;
  }

  List<List<int>> _digHoles(List<List<int>> solution, int cluesCount) {
    final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
    final positions = <(int, int)>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        positions.add((r, c));
      }
    }
    positions.shuffle(_random);

    int remaining = 81;
    for (final (r, c) in positions) {
      if (remaining <= cluesCount) break;

      final backup = puzzle[r][c];
      puzzle[r][c] = 0;

      final testGrid = List.generate(9, (i) => List<int>.from(puzzle[i]));
      if (SudokuSolver.countSolutions(testGrid, limit: 2) != 1) {
        puzzle[r][c] = backup;
      } else {
        remaining--;
      }
    }
    return puzzle;
  }
}
