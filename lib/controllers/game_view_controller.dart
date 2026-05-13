import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/difficulty.dart';
import '../models/drawing.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../models/sudoku_board.dart';
import '../models/technique.dart';
import '../services/hint_service.dart';
import '../services/puzzle_cache.dart';
import '../services/storage_service.dart';
import '../services/sudoku_generator.dart';

/// Encapsulates all game state and logic for the Sudoku game screen.
///
/// Separated from the UI layer (GameScreen) to improve testability and
/// maintainability. The controller manages game lifecycle, user interactions,
/// hint system, undo/redo, and auto-save.
class GameViewController extends ChangeNotifier {
  // --- Public state ---

  GameState _gameState = GameState(
    board: SudokuBoard.empty(),
    solution: List.generate(9, (_) => List.filled(9, 0)),
    difficulty: Difficulty.easy,
  );
  GameState get gameState => _gameState;

  final GameSettings _settings = GameSettings();
  GameSettings get settings => _settings;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  bool _isTimerStopped = false;
  bool get isTimerStopped => _isTimerStopped;

  int _persistentHighlightNumber = 0;
  int get persistentHighlightNumber => _persistentHighlightNumber;

  bool _drawingMode = false;
  bool get drawingMode => _drawingMode;

  DrawingTool _drawingTool = DrawingTool.pen;
  DrawingTool get drawingTool => _drawingTool;

  Color _drawingColor = const Color(0xFFE53935);
  Color get drawingColor => _drawingColor;

  List<DrawingElement> _drawingElements = [];
  List<DrawingElement> get drawingElements => _drawingElements;

  bool _showSmartHint = false;
  bool get showSmartHint => _showSmartHint;

  bool _hintStep2 = false;
  bool get hintStep2 => _hintStep2;

  TechniqueResult? _hintResult;
  TechniqueResult? get hintResult => _hintResult;

  List<List<int>>? _hintBoardValues;
  List<List<int>>? get hintBoardValues => _hintBoardValues;

  List<List<Set<int>>>? _hintBoardCandidates;
  List<List<Set<int>>>? get hintBoardCandidates => _hintBoardCandidates;

  // --- Internal state ---

  Timer? _timer;
  late List<List<int>> _initialPuzzle;
  late List<List<int>> _currentSolution;
  Difficulty _difficulty = Difficulty.easy;

  bool get isTimerRunning =>
      _gameState.status == GameStatus.playing &&
      !_isPaused &&
      !_isTimerStopped;

  // --- Lifecycle ---

  /// Initialize a new game with the given difficulty.
  Future<void> initGame(Difficulty difficulty) async {
    _difficulty = difficulty;
    _isLoading = true;
    notifyListeners();

    List<List<int>> puzzleValues;
    List<List<int>> solution;

    if (difficulty.index >= Difficulty.expert.index) {
      final cached = await PuzzleCache.getPuzzle(difficulty);
      puzzleValues = cached.puzzle.toValues();
      solution = cached.solution;
    } else {
      final result = await compute(_generatePuzzle, difficulty);
      puzzleValues = result.puzzleValues;
      solution = result.solution;
    }

    _initialPuzzle = puzzleValues;
    _currentSolution = solution;
    _persistentHighlightNumber = 0;

    _gameState = GameState(
      board: SudokuBoard.fromValues(puzzleValues),
      solution: solution,
      difficulty: difficulty,
    );
    _isPaused = false;
    _isTimerStopped = false;
    _drawingElements = [];
    _drawingMode = false;
    _isLoading = false;
    notifyListeners();

    _startTimer();
    _autoSave();
  }

  /// Load a previously saved game.
  void loadSavedGame(Map<String, dynamic> data, Difficulty fallback) {
    final puzzleValues = _parse2DList(data['puzzleValues']);
    final currentValues = _parse2DList(data['currentValues']);
    final solution = _parse2DList(data['solution']);
    final notesRaw = data['notes'] as List;
    final notes = List.generate(
      9,
      (r) => List.generate(
        9,
        (c) => Set<int>.from((notesRaw[r] as List)[c] as List),
      ),
    );
    final diffName = data['difficulty'] as String;
    final difficulty = Difficulty.values.firstWhere(
      (d) => d.name == diffName,
      orElse: () => fallback,
    );

    _difficulty = difficulty;
    _initialPuzzle = puzzleValues;
    _currentSolution = solution;
    _persistentHighlightNumber = 0;

    final board = SudokuBoard.fromValues(puzzleValues);
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = board.getCell(r, c);
        if (!cell.isFixed) {
          cell.value = currentValues[r][c];
          cell.notes = notes[r][c];
        }
      }
    }
    board.validateAll();

    _gameState = GameState(
      board: board,
      solution: solution,
      difficulty: difficulty,
      mistakes: data['mistakes'] ?? 0,
      hintsUsed: data['hintsUsed'] ?? 0,
      elapsed: Duration(seconds: data['elapsed'] ?? 0),
    );
    _isLoading = false;
    notifyListeners();
    _startTimer();
  }

  /// Restart the same puzzle from scratch.
  void restartSamePuzzle() {
    final board = SudokuBoard.fromValues(_initialPuzzle);
    _persistentHighlightNumber = 0;
    _gameState = GameState(
      board: board,
      solution: _currentSolution,
      difficulty: _difficulty,
    );
    _isPaused = false;
    _isTimerStopped = false;
    _drawingElements = [];
    _drawingMode = false;
    notifyListeners();
    _startTimer();
    _autoSave();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Timer ---

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isTimerRunning) {
        _gameState.elapsed += const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  void togglePause() {
    if (_isLoading || _gameState.status != GameStatus.playing) return;
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void onMouseEnter() {
    if (_isTimerStopped) {
      _isTimerStopped = false;
      notifyListeners();
    }
  }

  void onMouseExit() {
    if (!_isLoading &&
        _gameState.status == GameStatus.playing &&
        _settings.autoPauseOnLeave) {
      _isTimerStopped = true;
      notifyListeners();
    }
  }

  // --- Cell interaction ---

  void onCellTap((int, int) position) {
    if (_gameState.status != GameStatus.playing || _isPaused) return;
    final (row, col) = position;
    final isSameSelection =
        _gameState.selectedRow == row && _gameState.selectedCol == col;

    if (isSameSelection) {
      _gameState.clearSelection();
      _persistentHighlightNumber = 0;
    } else {
      _gameState.selectCell(row, col);
      final tappedCell = _gameState.board.getCell(row, col);
      if (tappedCell.isFixed && tappedCell.value != 0) {
        _persistentHighlightNumber = tappedCell.value;
      }
    }
    notifyListeners();
  }

  void onNumberInput(int number) {
    if (_gameState.status != GameStatus.playing || _isPaused) return;
    if (!_gameState.hasSelection) return;

    final row = _gameState.selectedRow;
    final col = _gameState.selectedCol;
    final cell = _gameState.board.getCell(row, col);
    if (cell.isFixed) return;

    if (_gameState.isNotesMode) {
      _gameState.saveSnapshot();
      cell.toggleNote(number);
    } else {
      _gameState.saveSnapshot();
      _gameState.board.setValue(row, col, number,
          autoRemoveNotes: _settings.autoRemoveNotes);

      if (_gameState.solution[row][col] != number) {
        _gameState.mistakes++;
        cell.isError = true;
        cell.isWrongAnswer = true;
        if (_gameState.mistakes >= GameState.maxMistakes) {
          _gameState.status = GameStatus.completed;
          _timer?.cancel();
          StorageService.clearGame();
          StorageService.recordLoss(_gameState.difficulty.name);
        }
      } else {
        cell.isError = false;
        cell.isWrongAnswer = false;
      }

      _gameState.board.validateAll();

      if (_gameState.board.isComplete) {
        _gameState.status = GameStatus.completed;
        _timer?.cancel();
        StorageService.clearGame();
        StorageService.recordWin(
            _gameState.difficulty.name, _gameState.elapsed);
      }
    }
    notifyListeners();
    _autoSave();
  }

  void onDelete() {
    if (_gameState.status != GameStatus.playing || _isPaused) return;
    if (!_gameState.hasSelection) return;
    final row = _gameState.selectedRow;
    final col = _gameState.selectedCol;
    _gameState.saveSnapshot();
    _gameState.board.clearCell(row, col);
    _gameState.board.validateAll();
    notifyListeners();
    _autoSave();
  }

  void onNotesToggle() {
    _gameState.isNotesMode = !_gameState.isNotesMode;
    notifyListeners();
  }

  void onUndo() {
    if (_gameState.status != GameStatus.playing || _isPaused) return;
    final snapshot = _gameState.popSnapshot();
    if (snapshot == null) return;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = _gameState.board.getCell(r, c);
        if (!cell.isFixed) {
          cell.value = snapshot.values[r][c];
          cell.notes = Set<int>.from(snapshot.notes[r][c]);
          cell.isWrongAnswer = snapshot.wrongAnswers[r][c];
        }
      }
    }
    _gameState.selectCell(snapshot.row, snapshot.col);
    _gameState.board.validateAll();
    notifyListeners();
    _autoSave();
  }

  void onAutoNotes() {
    if (_gameState.status != GameStatus.playing || _isPaused) return;
    _gameState.saveSnapshot();
    _gameState.board.fillAllCandidates();
    notifyListeners();
    _autoSave();
  }

  Set<int> getActiveNotes() {
    if (!_gameState.isNotesMode || !_gameState.hasSelection) return const {};
    final cell = _gameState.board
        .getCell(_gameState.selectedRow, _gameState.selectedCol);
    if (cell.isFixed || cell.value != 0) return const {};
    return cell.notes;
  }

  // --- Drawing ---

  void toggleDrawingMode() {
    _drawingMode = !_drawingMode;
    _drawingTool = _drawingMode ? DrawingTool.pen : DrawingTool.none;
    notifyListeners();
  }

  void setDrawingTool(DrawingTool tool) {
    _drawingTool = tool;
    notifyListeners();
  }

  void setDrawingColor(Color color) {
    _drawingColor = color;
    notifyListeners();
  }

  void undoDrawing() {
    if (_drawingElements.isNotEmpty) {
      _drawingElements = List.from(_drawingElements)..removeLast();
      notifyListeners();
    }
  }

  void clearDrawing() {
    _drawingElements = [];
    notifyListeners();
  }

  void setDrawingElements(List<DrawingElement> elements) {
    _drawingElements = elements;
    notifyListeners();
  }

  // --- Hint system ---

  void onHint() {
    if (_gameState.status != GameStatus.playing || _isPaused) return;

    final grid = _gameState.board.toValues();
    final candidates = _getHintCandidates();
    final result = HintService.getHintWithCandidates(grid, candidates);

    if (result != null) {
      _showSmartHint = true;
      _hintStep2 = false;
      _hintResult = result;
      _hintBoardValues = grid;
      _hintBoardCandidates = candidates;
      notifyListeners();
      return;
    }

    // Fallback: direct answer reveal
    if (!_gameState.hasSelection) return;
    final row = _gameState.selectedRow;
    final col = _gameState.selectedCol;
    final cell = _gameState.board.getCell(row, col);
    if (cell.isFixed) return;

    _gameState.saveSnapshot();
    _gameState.hintsUsed++;
    _gameState.board.setValue(row, col, _gameState.solution[row][col],
        autoRemoveNotes: _settings.autoRemoveNotes);
    cell.isError = false;
    _gameState.board.validateAll();

    if (_gameState.board.isComplete) {
      _gameState.status = GameStatus.completed;
      _timer?.cancel();
      StorageService.clearGame();
      StorageService.recordWin(
          _gameState.difficulty.name, _gameState.elapsed);
    }
    notifyListeners();
    _autoSave();
  }

  void applySmartHint() {
    if (_hintResult == null) return;

    _gameState.saveSnapshot();
    _gameState.hintsUsed++;

    _fillHintCandidates(_hintResult!);

    for (final entry in _hintResult!.placements.entries) {
      _gameState.board.setValue(
        entry.key.row, entry.key.col, entry.value,
        autoRemoveNotes: _settings.autoRemoveNotes,
      );
      _gameState.board.getCell(entry.key.row, entry.key.col).isError = false;
    }

    for (final entry in _hintResult!.eliminateCandidates.entries) {
      final cell = _gameState.board.getCell(entry.key.row, entry.key.col);
      if (cell.notes.isEmpty && cell.isEmpty) {
        cell.notes =
            _gameState.board.getCandidates(entry.key.row, entry.key.col);
      }
      cell.notes.removeAll(entry.value);
    }

    _gameState.board.validateAll();

    _showSmartHint = false;
    _hintStep2 = false;
    _hintResult = null;
    _hintBoardValues = null;
    _hintBoardCandidates = null;

    if (_gameState.board.isComplete) {
      _gameState.status = GameStatus.completed;
      _timer?.cancel();
      StorageService.clearGame();
      StorageService.recordWin(
          _gameState.difficulty.name, _gameState.elapsed);
    }
    notifyListeners();
    _autoSave();
  }

  void setHintStep2(bool value) {
    _hintStep2 = value;
    notifyListeners();
  }

  void dismissSmartHint() {
    _showSmartHint = false;
    _hintStep2 = false;
    _hintResult = null;
    _hintBoardValues = null;
    _hintBoardCandidates = null;
    notifyListeners();
  }

  // --- Utility ---

  String formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get isComplete =>
      _gameState.status == GameStatus.completed;

  bool get isWon =>
      _gameState.status == GameStatus.completed && _gameState.board.isComplete;

  bool get isLost =>
      _gameState.status == GameStatus.completed &&
      _gameState.mistakes >= GameState.maxMistakes &&
      !_gameState.board.isComplete;

  // --- Private helpers ---

  void _autoSave() async {
    if (_isLoading) return;
    if (_gameState.status != GameStatus.playing) return;
    final data = {
      'puzzleValues': _initialPuzzle,
      'currentValues': _gameState.board.toValues(),
      'notes': List.generate(
        9,
        (r) => List.generate(
          9,
          (c) => _gameState.board.getCell(r, c).notes.toList(),
        ),
      ),
      'solution': _currentSolution,
      'difficulty': _gameState.difficulty.name,
      'elapsed': _gameState.elapsed.inSeconds,
      'mistakes': _gameState.mistakes,
      'hintsUsed': _gameState.hintsUsed,
    };
    await StorageService.saveGame(data);
  }

  void _fillHintCandidates(TechniqueResult result) {
    final cellsToFill = <CellPosition>{
      ...result.highlightCells,
      ...result.relatedCells,
      ...result.eliminateCandidates.keys,
      ...result.placements.keys,
    };

    for (final pos in result.eliminateCandidates.keys) {
      for (int i = 0; i < 9; i++) {
        cellsToFill.add(CellPosition(pos.row, i));
        cellsToFill.add(CellPosition(i, pos.col));
      }
      final br = (pos.row ~/ 3) * 3, bc = (pos.col ~/ 3) * 3;
      for (int r = br; r < br + 3; r++) {
        for (int c = bc; c < bc + 3; c++) {
          cellsToFill.add(CellPosition(r, c));
        }
      }
    }
    for (final pos in result.placements.keys) {
      for (int i = 0; i < 9; i++) {
        cellsToFill.add(CellPosition(pos.row, i));
        cellsToFill.add(CellPosition(i, pos.col));
      }
      final br = (pos.row ~/ 3) * 3, bc = (pos.col ~/ 3) * 3;
      for (int r = br; r < br + 3; r++) {
        for (int c = bc; c < bc + 3; c++) {
          cellsToFill.add(CellPosition(r, c));
        }
      }
    }

    for (final pos in cellsToFill) {
      final cell = _gameState.board.getCell(pos.row, pos.col);
      if (cell.isEmpty && !cell.isFixed && cell.notes.isEmpty) {
        cell.notes = _gameState.board.getCandidates(pos.row, pos.col);
      }
    }
  }

  List<List<Set<int>>> _getHintCandidates() {
    final grid = _gameState.board.toValues();
    return List.generate(9, (r) => List.generate(9, (c) {
      if (grid[r][c] != 0) return <int>{};
      final computed = _gameState.board.getCandidates(r, c);
      final cell = _gameState.board.getCell(r, c);
      if (cell.notes.isNotEmpty) {
        return computed.intersection(cell.notes);
      }
      return computed;
    }));
  }

  List<List<int>> _parse2DList(dynamic raw) {
    return (raw as List)
        .map((row) => (row as List).map((v) => v as int).toList())
        .toList();
  }
}

// --- Top-level function for compute isolate ---

class GenerateResult {
  final List<List<int>> puzzleValues;
  final List<List<int>> solution;
  GenerateResult({required this.puzzleValues, required this.solution});
}

GenerateResult _generatePuzzle(Difficulty difficulty) {
  final generator = SudokuGenerator();
  final result = generator.generate(difficulty);
  return GenerateResult(
      puzzleValues: result.puzzle.toValues(), solution: result.solution);
}
