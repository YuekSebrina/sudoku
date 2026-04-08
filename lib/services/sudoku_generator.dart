import 'dart:math';

import '../data/abyss_puzzles.dart';
import '../models/difficulty.dart';
import '../models/sudoku_board.dart';
import 'dlx_solver.dart';
import 'sudoku_grader.dart';

class SudokuGenerator {
  final Random _random;

  SudokuGenerator({int? seed}) : _random = Random(seed);

  ({SudokuBoard puzzle, List<List<int>> solution}) generate(
      Difficulty difficulty) {
    if (difficulty == Difficulty.abyss) {
      return _generate17Clue(abyss17CluePuzzles, abyss17ClueSolutions);
    }
    if (difficulty == Difficulty.extreme) {
      return _generate17Clue(extreme17CluePuzzles, extreme17ClueSolutions);
    }
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

    for (int attempt = 0; attempt < 5; attempt++) {
      final solution = _generateFullSolution();
      final puzzle = _digHolesDeep(solution, difficulty.clues);

      int clueCount = _countClues(puzzle);
      final score = SudokuGrader.grade(puzzle);
      final effective = score < 0 ? 9999 : score;

      if (effective > bestScore ||
          (effective == bestScore && clueCount < bestClues)) {
        bestScore = effective;
        bestClues = clueCount;
        bestPuzzle = puzzle;
        bestSolution = solution;
      }

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

  /// Extreme/Abyss: pick from pre-computed 17-clue puzzle database.
  ({SudokuBoard puzzle, List<List<int>> solution}) _generate17Clue(
    List<String> puzzles, List<String> solutions,
  ) {
    final index = _random.nextInt(puzzles.length);
    final puzzle = List.generate(9, (r) =>
      List.generate(9, (c) => int.parse(puzzles[index][r * 9 + c])),
    );
    final solution = List.generate(9, (r) =>
      List.generate(9, (c) => int.parse(solutions[index][r * 9 + c])),
    );
    return (
      puzzle: SudokuBoard.fromValues(puzzle),
      solution: solution,
    );
  }

  List<List<int>> _generateFullSolution() {
    final grid = List.generate(9, (_) => List.filled(9, 0));
    DlxSolver.solveRandom(grid, _random);
    return grid;
  }

  List<List<int>> _digHoles(List<List<int>> solution, int cluesCount) {
    final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
    final positions = _shuffledPositions();

    int remaining = 81;
    for (final (r, c) in positions) {
      if (remaining <= cluesCount) break;
      final backup = puzzle[r][c];
      puzzle[r][c] = 0;

      final test = List.generate(9, (i) => List<int>.from(puzzle[i]));
      if (DlxSolver.countSolutions(test, limit: 2) != 1) {
        puzzle[r][c] = backup;
      } else {
        remaining--;
      }
    }
    return puzzle;
  }

  List<List<int>> _digHolesDeep(List<List<int>> solution, int targetClues) {
    final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));

    _digPass(puzzle, targetClues);
    final remaining = _countClues(puzzle);
    if (remaining > targetClues) {
      _digPass(puzzle, targetClues);
    }

    return puzzle;
  }

  int _digPass(List<List<int>> puzzle, int targetClues) {
    final leftover = <(int, int)>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (puzzle[r][c] != 0) leftover.add((r, c));
      }
    }
    leftover.shuffle(_random);

    int remaining = leftover.length;
    for (final (r, c) in leftover) {
      if (remaining <= targetClues) break;
      if (puzzle[r][c] == 0) continue;
      final backup = puzzle[r][c];
      puzzle[r][c] = 0;

      final test = List.generate(9, (i) => List<int>.from(puzzle[i]));
      if (DlxSolver.countSolutions(test, limit: 2) != 1) {
        puzzle[r][c] = backup;
      } else {
        remaining--;
      }
    }
    return remaining;
  }

  int _countClues(List<List<int>> puzzle) {
    int count = 0;
    for (final row in puzzle) {
      for (final v in row) {
        if (v != 0) count++;
      }
    }
    return count;
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
