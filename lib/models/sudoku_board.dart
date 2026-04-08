import 'sudoku_cell.dart';

class SudokuBoard {
  final List<List<SudokuCell>> cells;

  SudokuBoard({required this.cells});

  factory SudokuBoard.empty() {
    return SudokuBoard(
      cells: List.generate(
        9,
        (row) => List.generate(
          9,
          (col) => SudokuCell(row: row, col: col),
        ),
      ),
    );
  }

  factory SudokuBoard.fromValues(List<List<int>> values, {List<List<int>>? solution}) {
    return SudokuBoard(
      cells: List.generate(
        9,
        (row) => List.generate(9, (col) {
          final v = values[row][col];
          return SudokuCell(
            row: row,
            col: col,
            value: v,
            isFixed: v != 0,
          );
        }),
      ),
    );
  }

  SudokuCell getCell(int row, int col) => cells[row][col];

  void setValue(int row, int col, int value, {bool autoRemoveNotes = false}) {
    final cell = cells[row][col];
    if (!cell.isFixed) {
      cell.value = value;
      cell.notes.clear();
      if (autoRemoveNotes && value != 0) {
        _removeRelatedNotes(row, col, value);
      }
    }
  }

  void _removeRelatedNotes(int row, int col, int value) {
    for (int c = 0; c < 9; c++) {
      cells[row][c].notes.remove(value);
    }
    for (int r = 0; r < 9; r++) {
      cells[r][col].notes.remove(value);
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        cells[r][c].notes.remove(value);
      }
    }
  }

  void clearCell(int row, int col) {
    final cell = cells[row][col];
    if (!cell.isFixed) {
      cell.value = 0;
      cell.notes.clear();
      cell.isError = false;
    }
  }

  bool isRowValid(int row) {
    final seen = <int>{};
    for (int col = 0; col < 9; col++) {
      final v = cells[row][col].value;
      if (v != 0 && !seen.add(v)) return false;
    }
    return true;
  }

  bool isColValid(int col) {
    final seen = <int>{};
    for (int row = 0; row < 9; row++) {
      final v = cells[row][col].value;
      if (v != 0 && !seen.add(v)) return false;
    }
    return true;
  }

  bool isBoxValid(int boxRow, int boxCol) {
    final seen = <int>{};
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        final v = cells[r][c].value;
        if (v != 0 && !seen.add(v)) return false;
      }
    }
    return true;
  }

  bool isCellValid(int row, int col) {
    final value = cells[row][col].value;
    if (value == 0) return true;

    for (int c = 0; c < 9; c++) {
      if (c != col && cells[row][c].value == value) return false;
    }
    for (int r = 0; r < 9; r++) {
      if (r != row && cells[r][col].value == value) return false;
    }

    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (r != row && c != col && cells[r][c].value == value) return false;
      }
    }
    return true;
  }

  void validateAll() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        cells[r][c].isError = cells[r][c].value != 0 && !isCellValid(r, c);
      }
    }
  }

  bool get isComplete {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].isEmpty || cells[r][c].isError) return false;
      }
    }
    return true;
  }

  Set<int> getCandidates(int row, int col) {
    if (cells[row][col].value != 0) return {};
    final used = <int>{};
    for (int c = 0; c < 9; c++) {
      used.add(cells[row][c].value);
    }
    for (int r = 0; r < 9; r++) {
      used.add(cells[r][col].value);
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        used.add(cells[r][c].value);
      }
    }
    return {for (int n = 1; n <= 9; n++) if (!used.contains(n)) n};
  }

  void fillAllCandidates() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = cells[r][c];
        if (cell.isEmpty && !cell.isFixed) {
          cell.notes = getCandidates(r, c);
        }
      }
    }
  }

  Map<int, int> getRemainingCounts() {
    final counts = {for (int n = 1; n <= 9; n++) n: 9};
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final v = cells[r][c].value;
        if (v != 0) counts[v] = counts[v]! - 1;
      }
    }
    return counts;
  }

  bool get isFull {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].isEmpty) return false;
      }
    }
    return true;
  }

  SudokuBoard copy() {
    return SudokuBoard(
      cells: List.generate(
        9,
        (r) => List.generate(9, (c) => cells[r][c].copyWith()),
      ),
    );
  }

  List<List<int>> toValues() {
    return List.generate(
      9,
      (r) => List.generate(9, (c) => cells[r][c].value),
    );
  }
}
