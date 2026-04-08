class SudokuCell {
  final int row;
  final int col;
  int value;
  final bool isFixed;
  Set<int> notes;
  bool isError;

  /// Tracks whether this cell's value doesn't match the solution.
  /// Unlike [isError] (which tracks visible conflicts), this persists
  /// through [validateAll] so the user can see their mistake.
  bool isWrongAnswer;

  SudokuCell({
    required this.row,
    required this.col,
    this.value = 0,
    this.isFixed = false,
    Set<int>? notes,
    this.isError = false,
    this.isWrongAnswer = false,
  }) : notes = notes ?? {};

  bool get isEmpty => value == 0;

  int get boxIndex => (row ~/ 3) * 3 + (col ~/ 3);

  void reset() {
    if (!isFixed) {
      value = 0;
      notes.clear();
      isError = false;
      isWrongAnswer = false;
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
    bool? isWrongAnswer,
  }) {
    return SudokuCell(
      row: row ?? this.row,
      col: col ?? this.col,
      value: value ?? this.value,
      isFixed: isFixed ?? this.isFixed,
      notes: notes ?? Set.from(this.notes),
      isError: isError ?? this.isError,
      isWrongAnswer: isWrongAnswer ?? this.isWrongAnswer,
    );
  }
}
