import '../../models/technique.dart';
import 'technique_utils.dart';

/// Advanced-level techniques (高级).
///
/// Includes: Naked Triple, X-Wing, Hidden Pair, Hidden Triple,
/// Swordfish, Skyscraper, XY-Wing, Strong Links (2), XYZ-Wing.
class AdvancedTechniques {
  // ---------------------------------------------------------------------------
  // Naked Triple (直观3数对 / 显性3数对)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findNakedTriple(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (final group in TechniqueUtils.allGroups()) {
      final cells = group
          .where((p) =>
              candidates[p.row][p.col].length >= 2 &&
              candidates[p.row][p.col].length <= 3)
          .toList();
      for (int i = 0; i < cells.length; i++) {
        for (int j = i + 1; j < cells.length; j++) {
          for (int k = j + 1; k < cells.length; k++) {
            final union = <int>{
              ...candidates[cells[i].row][cells[i].col],
              ...candidates[cells[j].row][cells[j].col],
              ...candidates[cells[k].row][cells[k].col],
            };
            if (union.length == 3) {
              final elim = <CellPosition, Set<int>>{};
              for (final p in group) {
                if (p != cells[i] && p != cells[j] && p != cells[k]) {
                  final toRemove =
                      candidates[p.row][p.col].intersection(union);
                  if (toRemove.isNotEmpty) {
                    elim[p] = toRemove;
                  }
                }
              }
              if (elim.isNotEmpty) {
                return TechniqueResult(
                  type: TechniqueType.nakedTriple,
                  description:
                      'R${cells[i].row + 1}C${cells[i].col + 1}、R${cells[j].row + 1}C${cells[j].col + 1}、'
                      'R${cells[k].row + 1}C${cells[k].col + 1} 形成三数组 {${union.join(",")}}，'
                      '可从同组其他格中删除这些数字',
                  highlightCells: [cells[i], cells[j], cells[k]],
                  relatedCells: elim.keys.toList(),
                  eliminateCandidates: elim,
                );
              }
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // X-Wing
  // ---------------------------------------------------------------------------

  static TechniqueResult? findXWing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // Row-based
    for (int n = 1; n <= 9; n++) {
      for (int r1 = 0; r1 < 9; r1++) {
        final cols1 = <int>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r1][c].contains(n)) cols1.add(c);
        }
        if (cols1.length != 2) continue;
        for (int r2 = r1 + 1; r2 < 9; r2++) {
          final cols2 = <int>[];
          for (int c = 0; c < 9; c++) {
            if (candidates[r2][c].contains(n)) cols2.add(c);
          }
          if (cols2.length == 2 &&
              cols2[0] == cols1[0] &&
              cols2[1] == cols1[1]) {
            final elim = <CellPosition, Set<int>>{};
            for (int r = 0; r < 9; r++) {
              if (r != r1 && r != r2) {
                if (candidates[r][cols1[0]].contains(n)) {
                  elim[CellPosition(r, cols1[0])] = {n};
                }
                if (candidates[r][cols1[1]].contains(n)) {
                  elim[CellPosition(r, cols1[1])] = {n};
                }
              }
            }
            if (elim.isNotEmpty) {
              final corners = [
                CellPosition(r1, cols1[0]),
                CellPosition(r1, cols1[1]),
                CellPosition(r2, cols1[0]),
                CellPosition(r2, cols1[1]),
              ];
              return TechniqueResult(
                type: TechniqueType.xWing,
                description:
                    '数字 $n 在第${r1 + 1}行和第${r2 + 1}行各只出现在第${cols1[0] + 1}、${cols1[1] + 1}列，'
                    '形成 X-Wing，可从这两列的其他行中删除 $n',
                highlightCells: corners,
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: n,
                lines: [
                  HighlightLine(corners[0], corners[3],
                      style: HighlightLineStyle.arrow, digit: n),
                  HighlightLine(corners[1], corners[2],
                      style: HighlightLineStyle.arrow, digit: n),
                ],
              );
            }
          }
        }
      }
      // Col-based
      for (int c1 = 0; c1 < 9; c1++) {
        final rows1 = <int>[];
        for (int r = 0; r < 9; r++) {
          if (candidates[r][c1].contains(n)) rows1.add(r);
        }
        if (rows1.length != 2) continue;
        for (int c2 = c1 + 1; c2 < 9; c2++) {
          final rows2 = <int>[];
          for (int r = 0; r < 9; r++) {
            if (candidates[r][c2].contains(n)) rows2.add(r);
          }
          if (rows2.length == 2 &&
              rows2[0] == rows1[0] &&
              rows2[1] == rows1[1]) {
            final elim = <CellPosition, Set<int>>{};
            for (int c = 0; c < 9; c++) {
              if (c != c1 && c != c2) {
                if (candidates[rows1[0]][c].contains(n)) {
                  elim[CellPosition(rows1[0], c)] = {n};
                }
                if (candidates[rows1[1]][c].contains(n)) {
                  elim[CellPosition(rows1[1], c)] = {n};
                }
              }
            }
            if (elim.isNotEmpty) {
              final corners = [
                CellPosition(rows1[0], c1),
                CellPosition(rows1[0], c2),
                CellPosition(rows1[1], c1),
                CellPosition(rows1[1], c2),
              ];
              return TechniqueResult(
                type: TechniqueType.xWing,
                description:
                    '数字 $n 在第${c1 + 1}列和第${c2 + 1}列各只出现在第${rows1[0] + 1}、${rows1[1] + 1}行，'
                    '形成 X-Wing，可从这两行的其他列中删除 $n',
                highlightCells: corners,
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: n,
                lines: [
                  HighlightLine(corners[0], corners[3],
                      style: HighlightLineStyle.arrow, digit: n),
                  HighlightLine(corners[1], corners[2],
                      style: HighlightLineStyle.arrow, digit: n),
                ],
              );
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Hidden Pair (隐性2数对)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findHiddenPair(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (final group in TechniqueUtils.allGroups()) {
      for (int n1 = 1; n1 <= 9; n1++) {
        for (int n2 = n1 + 1; n2 <= 9; n2++) {
          final pos1 = <CellPosition>[];
          final pos2 = <CellPosition>[];
          for (final p in group) {
            if (candidates[p.row][p.col].contains(n1)) pos1.add(p);
            if (candidates[p.row][p.col].contains(n2)) pos2.add(p);
          }
          if (pos1.length == 2 &&
              pos2.length == 2 &&
              pos1[0] == pos2[0] &&
              pos1[1] == pos2[1]) {
            final keep = {n1, n2};
            final elim = <CellPosition, Set<int>>{};
            for (final p in [pos1[0], pos1[1]]) {
              final toRemove =
                  candidates[p.row][p.col].difference(keep);
              if (toRemove.isNotEmpty) {
                elim[p] = toRemove;
              }
            }
            if (elim.isNotEmpty) {
              return TechniqueResult(
                type: TechniqueType.hiddenPair,
                description:
                    '数字 $n1 和 $n2 在同组中只出现在 R${pos1[0].row + 1}C${pos1[0].col + 1} '
                    '和 R${pos1[1].row + 1}C${pos1[1].col + 1}，形成隐性数对，'
                    '可删除这两格中的其他候选数',
                highlightCells: [pos1[0], pos1[1]],
                eliminateCandidates: elim,
              );
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Hidden Triple (隐性3数对)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findHiddenTriple(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (final group in TechniqueUtils.allGroups()) {
      for (int n1 = 1; n1 <= 9; n1++) {
        for (int n2 = n1 + 1; n2 <= 9; n2++) {
          for (int n3 = n2 + 1; n3 <= 9; n3++) {
            final posUnion = <CellPosition>{};
            for (final p in group) {
              final cands = candidates[p.row][p.col];
              if (cands.contains(n1) ||
                  cands.contains(n2) ||
                  cands.contains(n3)) {
                posUnion.add(p);
              }
            }
            if (posUnion.length == 3) {
              final cells = posUnion.toList();
              bool allPresent = true;
              for (final n in [n1, n2, n3]) {
                if (!cells
                    .any((p) => candidates[p.row][p.col].contains(n))) {
                  allPresent = false;
                  break;
                }
              }
              if (!allPresent) continue;

              final keep = {n1, n2, n3};
              final elim = <CellPosition, Set<int>>{};
              for (final p in cells) {
                final toRemove =
                    candidates[p.row][p.col].difference(keep);
                if (toRemove.isNotEmpty) {
                  elim[p] = toRemove;
                }
              }
              if (elim.isNotEmpty) {
                return TechniqueResult(
                  type: TechniqueType.hiddenTriple,
                  description:
                      '数字 $n1、$n2、$n3 在同组中只出现在 3 个格中，形成隐性三数组，'
                      '可删除这些格中的其他候选数',
                  highlightCells: cells,
                  eliminateCandidates: elim,
                );
              }
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Swordfish (剑鱼)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findSwordfish(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    // Row-based Swordfish
    for (int n = 1; n <= 9; n++) {
      final rowCols = <int, List<int>>{};
      for (int r = 0; r < 9; r++) {
        final cols = <int>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) cols.add(c);
        }
        if (cols.length >= 2 && cols.length <= 3) rowCols[r] = cols;
      }
      final rows = rowCols.keys.toList();
      for (int i = 0; i < rows.length; i++) {
        for (int j = i + 1; j < rows.length; j++) {
          for (int k = j + 1; k < rows.length; k++) {
            final colUnion = <int>{
              ...rowCols[rows[i]]!,
              ...rowCols[rows[j]]!,
              ...rowCols[rows[k]]!,
            };
            if (colUnion.length == 3) {
              final elim = <CellPosition, Set<int>>{};
              for (final c in colUnion) {
                for (int r = 0; r < 9; r++) {
                  if (r != rows[i] && r != rows[j] && r != rows[k]) {
                    if (candidates[r][c].contains(n)) {
                      elim[CellPosition(r, c)] = {n};
                    }
                  }
                }
              }
              if (elim.isNotEmpty) {
                final highlights = <CellPosition>[];
                for (final r in [rows[i], rows[j], rows[k]]) {
                  for (final c in rowCols[r]!) {
                    highlights.add(CellPosition(r, c));
                  }
                }
                return TechniqueResult(
                  type: TechniqueType.swordfish,
                  description:
                      '数字 $n 在第${rows[i] + 1}、${rows[j] + 1}、${rows[k] + 1}行形成 Swordfish，'
                      '可从第${colUnion.map((c) => c + 1).join("、")}列的其他行中删除 $n',
                  highlightCells: highlights,
                  relatedCells: elim.keys.toList(),
                  eliminateCandidates: elim,
                  targetNumber: n,
                );
              }
            }
          }
        }
      }

      // Col-based Swordfish
      final colRows = <int, List<int>>{};
      for (int c = 0; c < 9; c++) {
        final rows2 = <int>[];
        for (int r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) rows2.add(r);
        }
        if (rows2.length >= 2 && rows2.length <= 3) colRows[c] = rows2;
      }
      final cols = colRows.keys.toList();
      for (int i = 0; i < cols.length; i++) {
        for (int j = i + 1; j < cols.length; j++) {
          for (int k = j + 1; k < cols.length; k++) {
            final rowUnion = <int>{
              ...colRows[cols[i]]!,
              ...colRows[cols[j]]!,
              ...colRows[cols[k]]!,
            };
            if (rowUnion.length == 3) {
              final elim = <CellPosition, Set<int>>{};
              for (final r in rowUnion) {
                for (int c = 0; c < 9; c++) {
                  if (c != cols[i] && c != cols[j] && c != cols[k]) {
                    if (candidates[r][c].contains(n)) {
                      elim[CellPosition(r, c)] = {n};
                    }
                  }
                }
              }
              if (elim.isNotEmpty) {
                final highlights = <CellPosition>[];
                for (final c in [cols[i], cols[j], cols[k]]) {
                  for (final r in colRows[c]!) {
                    highlights.add(CellPosition(r, c));
                  }
                }
                return TechniqueResult(
                  type: TechniqueType.swordfish,
                  description:
                      '数字 $n 在第${cols[i] + 1}、${cols[j] + 1}、${cols[k] + 1}列形成 Swordfish，'
                      '可从第${rowUnion.map((r) => r + 1).join("、")}行的其他列中删除 $n',
                  highlightCells: highlights,
                  relatedCells: elim.keys.toList(),
                  eliminateCandidates: elim,
                  targetNumber: n,
                );
              }
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Skyscraper (摩天楼)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findSkyscraper(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int n = 1; n <= 9; n++) {
      // Row-based skyscraper
      final rowPositions = <int, List<int>>{};
      for (int r = 0; r < 9; r++) {
        final cols = <int>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) cols.add(c);
        }
        if (cols.length == 2) rowPositions[r] = cols;
      }
      final rows = rowPositions.keys.toList();
      for (int i = 0; i < rows.length; i++) {
        for (int j = i + 1; j < rows.length; j++) {
          final c1 = rowPositions[rows[i]]!;
          final c2 = rowPositions[rows[j]]!;
          for (int ci = 0; ci < 2; ci++) {
            for (int cj = 0; cj < 2; cj++) {
              if (c1[ci] == c2[cj]) {
                final topCol = c1[1 - ci];
                final bottomCol = c2[1 - cj];
                if (topCol == bottomCol) continue;
                final elim = <CellPosition, Set<int>>{};
                for (int r = 0; r < 9; r++) {
                  for (int c = 0; c < 9; c++) {
                    if (!candidates[r][c].contains(n)) continue;
                    if (r == rows[i] && c == topCol) continue;
                    if (r == rows[j] && c == bottomCol) continue;
                    final seesTop = (r == rows[i] ||
                        c == topCol ||
                        ((r ~/ 3) == (rows[i] ~/ 3) &&
                            (c ~/ 3) == (topCol ~/ 3)));
                    final seesBottom = (r == rows[j] ||
                        c == bottomCol ||
                        ((r ~/ 3) == (rows[j] ~/ 3) &&
                            (c ~/ 3) == (bottomCol ~/ 3)));
                    if (seesTop && seesBottom) {
                      elim[CellPosition(r, c)] = {n};
                    }
                  }
                }
                if (elim.isNotEmpty) {
                  return TechniqueResult(
                    type: TechniqueType.skyscraper,
                    description:
                        '数字 $n 在第${rows[i] + 1}行和第${rows[j] + 1}行形成摩天楼结构，'
                        '可删除能同时看到两个端点的格的候选数 $n',
                    highlightCells: [
                      CellPosition(rows[i], c1[0]),
                      CellPosition(rows[i], c1[1]),
                      CellPosition(rows[j], c2[0]),
                      CellPosition(rows[j], c2[1]),
                    ],
                    relatedCells: elim.keys.toList(),
                    eliminateCandidates: elim,
                    targetNumber: n,
                    lines: [
                      HighlightLine(
                        CellPosition(rows[i], c1[ci]),
                        CellPosition(rows[j], c2[cj]),
                        style: HighlightLineStyle.arrow,
                        digit: n,
                      ),
                    ],
                  );
                }
              }
            }
          }
        }
      }

      // Col-based skyscraper
      final colPositions = <int, List<int>>{};
      for (int c = 0; c < 9; c++) {
        final rowList = <int>[];
        for (int r = 0; r < 9; r++) {
          if (candidates[r][c].contains(n)) rowList.add(r);
        }
        if (rowList.length == 2) colPositions[c] = rowList;
      }
      final colKeys = colPositions.keys.toList();
      for (int i = 0; i < colKeys.length; i++) {
        for (int j = i + 1; j < colKeys.length; j++) {
          final r1 = colPositions[colKeys[i]]!;
          final r2 = colPositions[colKeys[j]]!;
          for (int ri = 0; ri < 2; ri++) {
            for (int rj = 0; rj < 2; rj++) {
              if (r1[ri] == r2[rj]) {
                final topRow = r1[1 - ri];
                final bottomRow = r2[1 - rj];
                if (topRow == bottomRow) continue;
                final elim = <CellPosition, Set<int>>{};
                for (int r = 0; r < 9; r++) {
                  for (int c = 0; c < 9; c++) {
                    if (!candidates[r][c].contains(n)) continue;
                    if (r == topRow && c == colKeys[i]) continue;
                    if (r == bottomRow && c == colKeys[j]) continue;
                    final seesTop = (r == topRow ||
                        c == colKeys[i] ||
                        ((r ~/ 3) == (topRow ~/ 3) &&
                            (c ~/ 3) == (colKeys[i] ~/ 3)));
                    final seesBottom = (r == bottomRow ||
                        c == colKeys[j] ||
                        ((r ~/ 3) == (bottomRow ~/ 3) &&
                            (c ~/ 3) == (colKeys[j] ~/ 3)));
                    if (seesTop && seesBottom) {
                      elim[CellPosition(r, c)] = {n};
                    }
                  }
                }
                if (elim.isNotEmpty) {
                  return TechniqueResult(
                    type: TechniqueType.skyscraper,
                    description:
                        '数字 $n 在第${colKeys[i] + 1}列和第${colKeys[j] + 1}列形成摩天楼结构，'
                        '可删除能同时看到两个端点的格的候选数 $n',
                    highlightCells: [
                      CellPosition(r1[0], colKeys[i]),
                      CellPosition(r1[1], colKeys[i]),
                      CellPosition(r2[0], colKeys[j]),
                      CellPosition(r2[1], colKeys[j]),
                    ],
                    relatedCells: elim.keys.toList(),
                    eliminateCandidates: elim,
                    targetNumber: n,
                    lines: [
                      HighlightLine(
                        CellPosition(r1[ri], colKeys[i]),
                        CellPosition(r2[rj], colKeys[j]),
                        style: HighlightLineStyle.arrow,
                        digit: n,
                      ),
                    ],
                  );
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // XY-Wing
  // ---------------------------------------------------------------------------

  static TechniqueResult? findXYWing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (candidates[r][c].length != 2) continue;
        final pivot = CellPosition(r, c);
        final pivotCands = candidates[r][c].toList();
        final a = pivotCands[0], b = pivotCands[1];

        final peerList = TechniqueUtils.peers(r, c);
        final wing1Candidates = <CellPosition>[];
        final wing2Candidates = <CellPosition>[];

        for (final peer in peerList) {
          final pc = candidates[peer.row][peer.col];
          if (pc.length != 2) continue;
          if (pc.contains(a) && !pc.contains(b)) wing1Candidates.add(peer);
          if (pc.contains(b) && !pc.contains(a)) wing2Candidates.add(peer);
        }

        for (final w1 in wing1Candidates) {
          final w1c = candidates[w1.row][w1.col];
          final cValue = w1c.firstWhere((x) => x != a);
          for (final w2 in wing2Candidates) {
            final w2c = candidates[w2.row][w2.col];
            if (!w2c.contains(cValue)) continue;
            final cCheck = w2c.firstWhere((x) => x != b);
            if (cCheck != cValue) continue;

            final elim = <CellPosition, Set<int>>{};
            for (int rr = 0; rr < 9; rr++) {
              for (int cc = 0; cc < 9; cc++) {
                if (!candidates[rr][cc].contains(cValue)) continue;
                final p = CellPosition(rr, cc);
                if (p == pivot || p == w1 || p == w2) continue;
                if (TechniqueUtils.sees(p, w1) &&
                    TechniqueUtils.sees(p, w2)) {
                  elim[p] = {cValue};
                }
              }
            }
            if (elim.isNotEmpty) {
              return TechniqueResult(
                type: TechniqueType.xyWing,
                description:
                    'R${r + 1}C${c + 1}{$a,$b} 为中心，'
                    'R${w1.row + 1}C${w1.col + 1}{$a,$cValue} 和 '
                    'R${w2.row + 1}C${w2.col + 1}{$b,$cValue} 为翼，'
                    '形成 XY-Wing，可从能看到两翼的格中删除 $cValue',
                highlightCells: [pivot, w1, w2],
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: cValue,
                lines: [
                  HighlightLine(pivot, w1,
                      style: HighlightLineStyle.arrow, digit: a),
                  HighlightLine(pivot, w2,
                      style: HighlightLineStyle.arrow, digit: b),
                ],
              );
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Strong Links (2-string kite)
  // ---------------------------------------------------------------------------

  static TechniqueResult? findStrongLinks2(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int n = 1; n <= 9; n++) {
      for (int r = 0; r < 9; r++) {
        final rowCols = <int>[];
        for (int c = 0; c < 9; c++) {
          if (candidates[r][c].contains(n)) rowCols.add(c);
        }
        if (rowCols.length != 2) continue;

        for (int c = 0; c < 9; c++) {
          final colRows = <int>[];
          for (int rr = 0; rr < 9; rr++) {
            if (candidates[rr][c].contains(n)) colRows.add(rr);
          }
          if (colRows.length != 2) continue;

          for (int ri = 0; ri < 2; ri++) {
            for (int ci = 0; ci < 2; ci++) {
              if (rowCols[ri] == c && colRows[ci] == r) {
                final endA = CellPosition(r, rowCols[1 - ri]);
                final endB = CellPosition(colRows[1 - ci], c);
                final shared = CellPosition(r, c);
                final elim = <CellPosition, Set<int>>{};
                for (int rr = 0; rr < 9; rr++) {
                  for (int cc = 0; cc < 9; cc++) {
                    if (!candidates[rr][cc].contains(n)) continue;
                    final p = CellPosition(rr, cc);
                    if (p == endA || p == endB || p == shared) continue;
                    if (TechniqueUtils.sees(p, endA) &&
                        TechniqueUtils.sees(p, endB) &&
                        TechniqueUtils.sees(p, shared)) {
                      elim[p] = {n};
                    }
                  }
                }

                if (elim.isNotEmpty) {
                  return TechniqueResult(
                    type: TechniqueType.strongLinks2,
                    description:
                        '数字 $n 在第${r + 1}行和第${c + 1}列形成强链（2数组），'
                        '可从${elim.keys.map((p) => "R${p.row + 1}C${p.col + 1}").join("、")}删除 $n',
                    highlightCells: [endA, endB, CellPosition(r, c)],
                    relatedCells: elim.keys.toList(),
                    eliminateCandidates: elim,
                    targetNumber: n,
                    lines: [
                      HighlightLine(
                        CellPosition(r, rowCols[0]),
                        CellPosition(r, rowCols[1]),
                        style: HighlightLineStyle.arrow,
                        digit: n,
                      ),
                      HighlightLine(
                        CellPosition(colRows[0], c),
                        CellPosition(colRows[1], c),
                        style: HighlightLineStyle.arrow,
                        digit: n,
                      ),
                    ],
                  );
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // XYZ-Wing
  // ---------------------------------------------------------------------------

  static TechniqueResult? findXYZWing(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
  ) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (candidates[r][c].length != 3) continue;
        final pivot = CellPosition(r, c);
        final pivotCands = candidates[r][c].toList();

        final peerList = TechniqueUtils.peers(r, c);
        final biValuePeers = peerList
            .where((p) => candidates[p.row][p.col].length == 2)
            .toList();

        for (int i = 0; i < biValuePeers.length; i++) {
          for (int j = i + 1; j < biValuePeers.length; j++) {
            final w1 = biValuePeers[i], w2 = biValuePeers[j];
            final w1c = candidates[w1.row][w1.col];
            final w2c = candidates[w2.row][w2.col];

            if (!candidates[r][c].containsAll(w1c)) continue;
            if (!candidates[r][c].containsAll(w2c)) continue;

            final wingUnion = {...w1c, ...w2c};
            if (wingUnion.length != 3) continue;
            if (!wingUnion.containsAll(pivotCands)) continue;

            final common = w1c.intersection(w2c);
            if (common.length != 1) continue;
            final z = common.first;

            final elim = <CellPosition, Set<int>>{};
            for (int rr = 0; rr < 9; rr++) {
              for (int cc = 0; cc < 9; cc++) {
                if (!candidates[rr][cc].contains(z)) continue;
                final p = CellPosition(rr, cc);
                if (p == pivot || p == w1 || p == w2) continue;
                if (TechniqueUtils.sees(p, pivot) &&
                    TechniqueUtils.sees(p, w1) &&
                    TechniqueUtils.sees(p, w2)) {
                  elim[p] = {z};
                }
              }
            }
            if (elim.isNotEmpty) {
              return TechniqueResult(
                type: TechniqueType.xyzWing,
                description:
                    'R${r + 1}C${c + 1}{${pivotCands.join(",")}} 为中心，'
                    '与两翼形成 XYZ-Wing，'
                    '可从能看到三格的位置删除 $z',
                highlightCells: [pivot, w1, w2],
                relatedCells: elim.keys.toList(),
                eliminateCandidates: elim,
                targetNumber: z,
                lines: [
                  HighlightLine(pivot, w1,
                      style: HighlightLineStyle.arrow, digit: z),
                  HighlightLine(pivot, w2,
                      style: HighlightLineStyle.arrow, digit: z),
                ],
              );
            }
          }
        }
      }
    }
    return null;
  }
}
