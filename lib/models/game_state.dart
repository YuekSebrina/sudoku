import 'difficulty.dart';
import 'sudoku_board.dart';

enum GameStatus { playing, paused, completed }

class GameState {
  final SudokuBoard board;
  final List<List<int>> solution;
  final Difficulty difficulty;
  GameStatus status;
  int selectedRow;
  int selectedCol;
  bool isNotesMode;
  int mistakes;
  int hintsUsed;
  Duration elapsed;
  final List<BoardSnapshot> _undoStack;

  static const int maxMistakes = 3;

  GameState({
    required this.board,
    required this.solution,
    required this.difficulty,
    this.status = GameStatus.playing,
    this.selectedRow = -1,
    this.selectedCol = -1,
    this.isNotesMode = false,
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.elapsed = Duration.zero,
    List<BoardSnapshot>? undoStack,
  }) : _undoStack = undoStack ?? [];

  bool get hasSelection => selectedRow >= 0 && selectedCol >= 0;

  bool get canUndo => _undoStack.isNotEmpty;

  void saveSnapshot() {
    _undoStack.add(BoardSnapshot(
      values: board.toValues(),
      notes: List.generate(
        9,
        (r) => List.generate(9, (c) => Set<int>.from(board.getCell(r, c).notes)),
      ),
      wrongAnswers: List.generate(
        9,
        (r) => List.generate(9, (c) => board.getCell(r, c).isWrongAnswer),
      ),
      row: selectedRow,
      col: selectedCol,
    ));
  }

  BoardSnapshot? popSnapshot() {
    if (_undoStack.isEmpty) return null;
    return _undoStack.removeLast();
  }

  void selectCell(int row, int col) {
    selectedRow = row;
    selectedCol = col;
  }

  void clearSelection() {
    selectedRow = -1;
    selectedCol = -1;
  }
}

class BoardSnapshot {
  final List<List<int>> values;
  final List<List<Set<int>>> notes;
  final List<List<bool>> wrongAnswers;
  final int row;
  final int col;

  BoardSnapshot({
    required this.values,
    required this.notes,
    required this.wrongAnswers,
    required this.row,
    required this.col,
  });
}
