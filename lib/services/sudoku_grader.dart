/// Grades sudoku puzzle difficulty by simulating human solving techniques.
///
/// Technique scores (higher = harder):
/// - Naked Single: 1
/// - Hidden Single: 2
/// - Naked Pair: 4
/// - Pointing/Claiming: 5
/// - Naked Triple: 6
/// - Hidden Pair: 7
/// - X-Wing: 8
class SudokuGrader {
  /// Returns a difficulty score for the puzzle.
  /// Higher score = harder puzzle. Returns -1 if unsolvable by graded techniques.
  static int grade(List<List<int>> puzzle) {
    final grid = List.generate(9, (r) => List<int>.from(puzzle[r]));
    final candidates = List.generate(
      9,
      (r) => List.generate(9, (c) => <int>{}),
    );

    // Initialize candidates
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) {
          candidates[r][c] = _computeCandidates(grid, r, c);
        }
      }
    }

    int totalScore = 0;
    int maxTechnique = 0;
    bool progress = true;

    while (progress) {
      progress = false;

      // 1. Naked Singles (score: 1)
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (grid[r][c] == 0 && candidates[r][c].length == 1) {
            final val = candidates[r][c].first;
            grid[r][c] = val;
            candidates[r][c].clear();
            _eliminate(grid, candidates, r, c, val);
            totalScore += 1;
            if (maxTechnique < 1) maxTechnique = 1;
            progress = true;
          }
        }
      }
      if (progress) continue;

      // 2. Hidden Singles (score: 2)
      if (_solveHiddenSingles(grid, candidates)) {
        totalScore += 2;
        if (maxTechnique < 2) maxTechnique = 2;
        progress = true;
        continue;
      }

      // 3. Naked Pairs (score: 4)
      if (_eliminateNakedPairs(candidates)) {
        totalScore += 4;
        if (maxTechnique < 4) maxTechnique = 4;
        progress = true;
        continue;
      }

      // 4. Pointing Pairs / Claiming (score: 5)
      if (_eliminatePointing(candidates)) {
        totalScore += 5;
        if (maxTechnique < 5) maxTechnique = 5;
        progress = true;
        continue;
      }

      // 5. Naked Triples (score: 6)
      if (_eliminateNakedTriples(candidates)) {
        totalScore += 6;
        if (maxTechnique < 6) maxTechnique = 6;
        progress = true;
        continue;
      }

      // 6. Hidden Pairs (score: 7)
      if (_eliminateHiddenPairs(candidates)) {
        totalScore += 7;
        if (maxTechnique < 7) maxTechnique = 7;
        progress = true;
        continue;
      }

      // 7. X-Wing (score: 8)
      if (_eliminateXWing(candidates)) {
        totalScore += 8;
        if (maxTechnique < 8) maxTechnique = 8;
        progress = true;
        continue;
      }
    }

    // Check if solved
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) return -1; // Couldn't solve with these techniques
      }
    }

    // Combine max technique difficulty with total work
    return maxTechnique * 100 + totalScore;
  }

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

  static void _eliminate(
      List<List<int>> grid,
      List<List<Set<int>>> cands,
      int row,
      int col,
      int val) {
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

  static bool _solveHiddenSingles(
      List<List<int>> grid, List<List<Set<int>>> cands) {
    // Check rows
    for (int r = 0; r < 9; r++) {
      for (int n = 1; n <= 9; n++) {
        final positions = <int>[];
        for (int c = 0; c < 9; c++) {
          if (cands[r][c].contains(n)) positions.add(c);
        }
        if (positions.length == 1) {
          final c = positions[0];
          grid[r][c] = n;
          cands[r][c].clear();
          _eliminate(grid, cands, r, c, n);
          return true;
        }
      }
    }
    // Check cols
    for (int c = 0; c < 9; c++) {
      for (int n = 1; n <= 9; n++) {
        final positions = <int>[];
        for (int r = 0; r < 9; r++) {
          if (cands[r][c].contains(n)) positions.add(r);
        }
        if (positions.length == 1) {
          final r = positions[0];
          grid[r][c] = n;
          cands[r][c].clear();
          _eliminate(grid, cands, r, c, n);
          return true;
        }
      }
    }
    // Check boxes
    for (int br = 0; br < 9; br += 3) {
      for (int bc = 0; bc < 9; bc += 3) {
        for (int n = 1; n <= 9; n++) {
          final positions = <(int, int)>[];
          for (int r = br; r < br + 3; r++) {
            for (int c = bc; c < bc + 3; c++) {
              if (cands[r][c].contains(n)) positions.add((r, c));
            }
          }
          if (positions.length == 1) {
            final (r, c) = positions[0];
            grid[r][c] = n;
            cands[r][c].clear();
            _eliminate(grid, cands, r, c, n);
            return true;
          }
        }
      }
    }
    return false;
  }

  static List<List<(int, int)>> _allGroups() {
    final groups = <List<(int, int)>>[];
    for (int r = 0; r < 9; r++) {
      groups.add([for (int c = 0; c < 9; c++) (r, c)]);
    }
    for (int c = 0; c < 9; c++) {
      groups.add([for (int r = 0; r < 9; r++) (r, c)]);
    }
    for (int br = 0; br < 9; br += 3) {
      for (int bc = 0; bc < 9; bc += 3) {
        groups.add([
          for (int r = br; r < br + 3; r++)
            for (int c = bc; c < bc + 3; c++) (r, c)
        ]);
      }
    }
    return groups;
  }

  static bool _eliminateNakedPairs(List<List<Set<int>>> cands) {
    for (final group in _allGroups()) {
      final cells = group.where((p) => cands[p.$1][p.$2].length == 2).toList();
      for (int i = 0; i < cells.length; i++) {
        for (int j = i + 1; j < cells.length; j++) {
          final (r1, c1) = cells[i];
          final (r2, c2) = cells[j];
          if (cands[r1][c1].length == 2 &&
              cands[r1][c1].containsAll(cands[r2][c2]) &&
              cands[r2][c2].containsAll(cands[r1][c1])) {
            final pair = cands[r1][c1];
            bool changed = false;
            for (final (r, c) in group) {
              if ((r, c) != (r1, c1) && (r, c) != (r2, c2)) {
                for (final n in pair) {
                  if (cands[r][c].remove(n)) changed = true;
                }
              }
            }
            if (changed) return true;
          }
        }
      }
    }
    return false;
  }

  static bool _eliminatePointing(List<List<Set<int>>> cands) {
    for (int br = 0; br < 9; br += 3) {
      for (int bc = 0; bc < 9; bc += 3) {
        for (int n = 1; n <= 9; n++) {
          final positions = <(int, int)>[];
          for (int r = br; r < br + 3; r++) {
            for (int c = bc; c < bc + 3; c++) {
              if (cands[r][c].contains(n)) positions.add((r, c));
            }
          }
          if (positions.length < 2) continue;

          // All in same row?
          if (positions.every((p) => p.$1 == positions[0].$1)) {
            final row = positions[0].$1;
            bool changed = false;
            for (int c = 0; c < 9; c++) {
              if (c < bc || c >= bc + 3) {
                if (cands[row][c].remove(n)) changed = true;
              }
            }
            if (changed) return true;
          }
          // All in same col?
          if (positions.every((p) => p.$2 == positions[0].$2)) {
            final col = positions[0].$2;
            bool changed = false;
            for (int r = 0; r < 9; r++) {
              if (r < br || r >= br + 3) {
                if (cands[r][col].remove(n)) changed = true;
              }
            }
            if (changed) return true;
          }
        }
      }
    }
    return false;
  }

  static bool _eliminateNakedTriples(List<List<Set<int>>> cands) {
    for (final group in _allGroups()) {
      final cells =
          group.where((p) => cands[p.$1][p.$2].length >= 2 &&
              cands[p.$1][p.$2].length <= 3).toList();
      for (int i = 0; i < cells.length; i++) {
        for (int j = i + 1; j < cells.length; j++) {
          for (int k = j + 1; k < cells.length; k++) {
            final union = <int>{
              ...cands[cells[i].$1][cells[i].$2],
              ...cands[cells[j].$1][cells[j].$2],
              ...cands[cells[k].$1][cells[k].$2],
            };
            if (union.length == 3) {
              bool changed = false;
              for (final (r, c) in group) {
                if ((r, c) != cells[i] &&
                    (r, c) != cells[j] &&
                    (r, c) != cells[k]) {
                  for (final n in union) {
                    if (cands[r][c].remove(n)) changed = true;
                  }
                }
              }
              if (changed) return true;
            }
          }
        }
      }
    }
    return false;
  }

  static bool _eliminateHiddenPairs(List<List<Set<int>>> cands) {
    for (final group in _allGroups()) {
      for (int n1 = 1; n1 <= 9; n1++) {
        for (int n2 = n1 + 1; n2 <= 9; n2++) {
          final positions = <(int, int)>[];
          for (final (r, c) in group) {
            if (cands[r][c].contains(n1) || cands[r][c].contains(n2)) {
              positions.add((r, c));
            }
          }
          if (positions.length == 2) {
            final (r1, c1) = positions[0];
            final (r2, c2) = positions[1];
            if (cands[r1][c1].contains(n1) &&
                cands[r1][c1].contains(n2) &&
                cands[r2][c2].contains(n1) &&
                cands[r2][c2].contains(n2)) {
              bool changed = false;
              final keep = {n1, n2};
              for (final n in {...cands[r1][c1]}) {
                if (!keep.contains(n)) {
                  cands[r1][c1].remove(n);
                  changed = true;
                }
              }
              for (final n in {...cands[r2][c2]}) {
                if (!keep.contains(n)) {
                  cands[r2][c2].remove(n);
                  changed = true;
                }
              }
              if (changed) return true;
            }
          }
        }
      }
    }
    return false;
  }

  static bool _eliminateXWing(List<List<Set<int>>> cands) {
    // Row-based X-Wing
    for (int n = 1; n <= 9; n++) {
      for (int r1 = 0; r1 < 9; r1++) {
        final cols1 = <int>[];
        for (int c = 0; c < 9; c++) {
          if (cands[r1][c].contains(n)) cols1.add(c);
        }
        if (cols1.length != 2) continue;
        for (int r2 = r1 + 1; r2 < 9; r2++) {
          final cols2 = <int>[];
          for (int c = 0; c < 9; c++) {
            if (cands[r2][c].contains(n)) cols2.add(c);
          }
          if (cols2.length == 2 &&
              cols2[0] == cols1[0] &&
              cols2[1] == cols1[1]) {
            bool changed = false;
            for (int r = 0; r < 9; r++) {
              if (r != r1 && r != r2) {
                if (cands[r][cols1[0]].remove(n)) changed = true;
                if (cands[r][cols1[1]].remove(n)) changed = true;
              }
            }
            if (changed) return true;
          }
        }
      }
      // Col-based X-Wing
      for (int c1 = 0; c1 < 9; c1++) {
        final rows1 = <int>[];
        for (int r = 0; r < 9; r++) {
          if (cands[r][c1].contains(n)) rows1.add(r);
        }
        if (rows1.length != 2) continue;
        for (int c2 = c1 + 1; c2 < 9; c2++) {
          final rows2 = <int>[];
          for (int r = 0; r < 9; r++) {
            if (cands[r][c2].contains(n)) rows2.add(r);
          }
          if (rows2.length == 2 &&
              rows2[0] == rows1[0] &&
              rows2[1] == rows1[1]) {
            bool changed = false;
            for (int c = 0; c < 9; c++) {
              if (c != c1 && c != c2) {
                if (cands[rows1[0]][c].remove(n)) changed = true;
                if (cands[rows1[1]][c].remove(n)) changed = true;
              }
            }
            if (changed) return true;
          }
        }
      }
    }
    return false;
  }
}
