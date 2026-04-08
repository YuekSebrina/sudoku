import '../models/technique.dart';
import 'technique_finder.dart';

/// Grades sudoku difficulty by step-by-step solving.
/// Score = pure sum of per-step difficulty points.
///
/// Calibrated against 33 reference puzzles:
///   简单: ~480, 中级: ~580, 困难: ~680,
///   专家: ~890, 极端: ~1130, 深渊: ~1500+
class SudokuGrader {
  static int stepScore(TechniqueType type) {
    switch (type) {
      case TechniqueType.boxHiddenSingle:
      case TechniqueType.rowHiddenSingle:
      case TechniqueType.colHiddenSingle:
        return 12;
      case TechniqueType.nakedSingle:
        return 8;
      case TechniqueType.boxElimination:
      case TechniqueType.rowElimination:
      case TechniqueType.colElimination:
        return 16;
      case TechniqueType.explicitBoxLineReduction:
      case TechniqueType.hiddenBoxLineReduction:
      case TechniqueType.lineBoxClaiming:
        return 18;
      case TechniqueType.nakedPair:
        return 24;
      case TechniqueType.nakedTriple:
      case TechniqueType.explicitNakedTriple:
        return 38;
      case TechniqueType.hiddenPair:
        return 50;
      case TechniqueType.xWing:
        return 68;
      case TechniqueType.swordfish:
      case TechniqueType.hiddenTriple:
        return 85;
      case TechniqueType.skyscraper:
      case TechniqueType.xyWing:
      case TechniqueType.strongLinks2:
        return 45;
      case TechniqueType.xyzWing:
      case TechniqueType.strongLinks3:
        return 90;
      case TechniqueType.bug1:
      case TechniqueType.bug2:
      case TechniqueType.vwxyzWing:
      case TechniqueType.uvwxyzWing:
        return 120;
      case TechniqueType.biDirectionalXCycle:
      case TechniqueType.biDirectionalCycle:
        return 145;
      case TechniqueType.cellForcingChain:
      case TechniqueType.regionForcingChain:
        return 175;
    }
  }

  static int grade(List<List<int>> puzzle) {
    final grid = List.generate(9, (r) => List<int>.from(puzzle[r]));
    final candidates = TechniqueFinder.computeAllCandidates(grid);

    int clues = 0;
    for (final row in grid) for (final v in row) if (v != 0) clues++;
    int totalScore = ((clues - 17).clamp(0, 20)) * 6;
    int maxStep = 0;
    int iterations = 0;

    while (iterations < 500) {
      iterations++;

      bool solved = true;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (grid[r][c] == 0) { solved = false; break; }
        }
        if (!solved) break;
      }
      if (solved) break;

      final result = TechniqueFinder.findNext(grid, candidates);
      if (result == null) {
        int remaining = 0;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (grid[r][c] == 0) remaining++;
          }
        }
        // Unsolved cells need very hard techniques — heavy penalty
        totalScore += remaining * 45 + maxStep * 3;
        break;
      }

      final score = stepScore(result.type);
      totalScore += score;
      if (score > maxStep) maxStep = score;

      for (final entry in result.placements.entries) {
        grid[entry.key.row][entry.key.col] = entry.value;
        candidates[entry.key.row][entry.key.col].clear();
        _eliminate(candidates, entry.key.row, entry.key.col, entry.value);
      }
      for (final entry in result.eliminateCandidates.entries) {
        candidates[entry.key.row][entry.key.col].removeAll(entry.value);
      }

      bool changed = true;
      while (changed) {
        changed = false;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (grid[r][c] == 0 && candidates[r][c].length == 1) {
              final val = candidates[r][c].first;
              grid[r][c] = val;
              candidates[r][c].clear();
              _eliminate(candidates, r, c, val);
              totalScore += 9;
              changed = true;
            }
          }
        }
      }
    }

    return totalScore;
  }

  static void _eliminate(List<List<Set<int>>> cands, int row, int col, int val) {
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
}
