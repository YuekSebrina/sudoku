class SudokuCell {
  final int row;
  final int col;
  int value;
  final bool isFixed;
  Set<int> notes;
  bool isError;

  SudokuCell({
    required this.row,
    required this.col,
    this.value = 0,
    this.isFixed = false,
    Set<int>? notes,
    this.isError = false,
  }) : notes = notes ?? {};

  bool get isEmpty => value == 0;

  int get boxIndex => (row ~/ 3) * 3 + (col ~/ 3);

  void reset() {
    if (!isFixed) {
      value = 0;
      notes.clear();
      isError = false;
    }
  }

  void toggleNote(int number) {
    if (isFixed) return;
    if (notes.contains(number)) {
      notes.remove(number);
    } else {
      notes.add(number);
    }
    value = 0;
  }

  SudokuCell copyWith({
    int? row,
    int? col,
    int? value,
    bool? isFixed,
    Set<int>? notes,
    bool? isError,
  }) {
    return SudokuCell(
      row: row ?? this.row,
      col: col ?? this.col,
      value: value ?? this.value,
      isFixed: isFixed ?? this.isFixed,
      notes: notes ?? Set.from(this.notes),
      isError: isError ?? this.isError,
    );
  }
}
