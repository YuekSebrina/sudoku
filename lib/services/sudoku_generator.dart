import 'dart:math';

import '../models/difficulty.dart';
import '../models/sudoku_board.dart';
import 'sudoku_grader.dart';
import 'sudoku_solver.dart';

class SudokuGenerator {
  final Random _random;

  SudokuGenerator({int? seed}) : _random = Random(seed);

  ({SudokuBoard puzzle, List<List<int>> solution}) generate(
      Difficulty difficulty) {
    if (difficulty.index >= Difficulty.expert.index) {
      return _generateHard(difficulty);
    }
    return _generateNormal(difficulty);
  }

  ({SudokuBoard puzzle, List<List<int>> solution}) _generateNormal(
      Difficulty difficulty) {
    List<List<int>>? bestPuzzle;
    List<List<int>>? bestSolution;
    int bestScore = -1;

    for (int attempt = 0; attempt < 10; attempt++) {
      final solution = _generateFullSolution();
      final puzzle = _digHoles(solution, difficulty.clues);
      final score = SudokuGrader.grade(puzzle);
      if (score < 0) continue;

      if (score >= difficulty.minScore && score <= difficulty.maxScore) {
        return (
          puzzle: SudokuBoard.fromValues(puzzle),
          solution: solution,
        );
      }
      if (score > bestScore) {
        bestScore = score;
        bestPuzzle = puzzle;
        bestSolution = solution;
      }
    }

    if (bestPuzzle != null && bestSolution != null) {
      return (
        puzzle: SudokuBoard.fromValues(bestPuzzle),
        solution: bestSolution,
      );
    }
    final solution = _generateFullSolution();
    return (
      puzzle: SudokuBoard.fromValues(_digHoles(solution, difficulty.clues)),
      solution: solution,
    );
  }

  ({SudokuBoard puzzle, List<List<int>> solution}) _generateHard(
      Difficulty difficulty) {
    List<List<int>>? bestPuzzle;
    List<List<int>>? bestSolution;
    int bestScore = -2;
    int bestClues = 99;

    final maxAttempts = difficulty == Difficulty.abyss ? 8 : 5;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final solution = _generateFullSolution();
      final puzzle = _digHolesDeep(solution, difficulty.clues);

      int clueCount = 0;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (puzzle[r][c] != 0) clueCount++;
        }
      }

      final score = SudokuGrader.grade(puzzle);
      // -1 = needs techniques beyond grader = treat as hardest
      final effective = score < 0 ? 9999 : score;

      if (effective > bestScore ||
          (effective == bestScore && clueCount < bestClues)) {
        bestScore = effective;
        bestClues = clueCount;
        bestPuzzle = puzzle;
        bestSolution = solution;
      }

      // Early exit if we found a great puzzle
      if (score < 0 && clueCount <= difficulty.clues) break;
      if (effective >= 800 && clueCount <= difficulty.clues + 1) break;
    }

    if (bestPuzzle != null && bestSolution != null) {
      return (
        puzzle: SudokuBoard.fromValues(bestPuzzle),
        solution: bestSolution,
      );
    }

    final solution = _generateFullSolution();
    return (
      puzzle: SudokuBoard.fromValues(_digHoles(solution, difficulty.clues)),
      solution: solution,
    );
  }

  List<List<int>> _generateFullSolution() {
    final grid = List.generate(9, (_) => List.filled(9, 0));
    SudokuSolver.solveRandom(grid, _random);
    return grid;
  }

  /// Standard digging
  List<List<int>> _digHoles(List<List<int>> solution, int cluesCount) {
    final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
    final positions = _shuffledPositions();

    int remaining = 81;
    for (final (r, c) in positions) {
      if (remaining <= cluesCount) break;
      final backup = puzzle[r][c];
      puzzle[r][c] = 0;

      final test = List.generate(9, (i) => List<int>.from(puzzle[i]));
      if (SudokuSolver.countSolutions(test, limit: 2) != 1) {
        puzzle[r][c] = backup;
      } else {
        remaining--;
      }
    }
    return puzzle;
  }

  /// Deep digging: two passes to push clue count as low as possible
  List<List<int>> _digHolesDeep(List<List<int>> solution, int targetClues) {
    final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));

    // Pass 1: random order
    final positions = _shuffledPositions();
    int remaining = 81;
    for (final (r, c) in positions) {
      if (remaining <= targetClues) break;
      final backup = puzzle[r][c];
      if (backup == 0) continue;
      puzzle[r][c] = 0;

      final test = List.generate(9, (i) => List<int>.from(puzzle[i]));
      if (SudokuSolver.countSolutions(test, limit: 2) != 1) {
        puzzle[r][c] = backup;
      } else {
        remaining--;
      }
    }

    // Pass 2: retry remaining clues in different order
    if (remaining > targetClues) {
      final leftover = <(int, int)>[];
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (puzzle[r][c] != 0) leftover.add((r, c));
        }
      }
      leftover.shuffle(_random);

      for (final (r, c) in leftover) {
        if (remaining <= targetClues) break;
        final backup = puzzle[r][c];
        puzzle[r][c] = 0;

        final test = List.generate(9, (i) => List<int>.from(puzzle[i]));
        if (SudokuSolver.countSolutions(test, limit: 2) != 1) {
          puzzle[r][c] = backup;
        } else {
          remaining--;
        }
      }
    }

    return puzzle;
  }

  List<(int, int)> _shuffledPositions() {
    final positions = <(int, int)>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        positions.add((r, c));
      }
    }
    positions.shuffle(_random);
    return positions;
  }
}
