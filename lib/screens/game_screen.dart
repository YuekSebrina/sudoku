import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import '../theme/app_theme.dart';
import '../widgets/drawing_overlay.dart';
import '../widgets/drawing_toolbar.dart';
import '../widgets/interactive_tutorial_board.dart';
import '../widgets/number_pad.dart';
import '../widgets/sudoku_board_widget.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final Map<String, dynamic>? savedGame;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const GameScreen({
    super.key,
    required this.difficulty,
    this.savedGame,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  final GameSettings _settings = GameSettings();
  Timer? _timer;
  bool _isLoading = true;
  bool _isPaused = false;
  bool _isTimerStopped = false;
  int _persistentHighlightNumber = 0;
  late List<List<int>> _initialPuzzle;
  late List<List<int>> _currentSolution;

  bool _drawingMode = false;
  DrawingTool _drawingTool = DrawingTool.pen;
  Color _drawingColor = const Color(0xFFE53935);
  List<DrawingElement> _drawingElements = [];

  bool _showSmartHint = false;
  bool _hintStep2 = false;
  TechniqueResult? _hintResult;
  List<List<int>>? _hintBoardValues;
  List<List<Set<int>>>? _hintBoardCandidates;

  @override
  void initState() {
    super.initState();
    if (widget.savedGame != null) {
      _loadSavedGame(widget.savedGame!);
    } else {
      _initGame();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePause() {
    if (_isLoading || _gameState.status != GameStatus.playing) return;
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _initGame() async {
    setState(() => _isLoading = true);

    List<List<int>> puzzleValues;
    List<List<int>> solution;

    // Use cache for hard difficulties, direct compute for easier ones
    if (widget.difficulty.index >= Difficulty.expert.index) {
      final cached = await PuzzleCache.getPuzzle(widget.difficulty);
      puzzleValues = cached.puzzle.toValues();
      solution = cached.solution;
    } else {
      final result = await compute(_generatePuzzle, widget.difficulty);
      puzzleValues = result.puzzleValues;
      solution = result.solution;
    }

    _initialPuzzle = puzzleValues;
    _currentSolution = solution;
    _persistentHighlightNumber = 0;

    setState(() {
      _gameState = GameState(
        board: SudokuBoard.fromValues(puzzleValues),
        solution: solution,
        difficulty: widget.difficulty,
      );
      _isPaused = false;
      _isTimerStopped = false;
      _drawingElements = [];
      _drawingMode = false;
      _isLoading = false;
    });

    _startTimer();
    _autoSave();
  }

  void _loadSavedGame(Map<String, dynamic> data) {
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
      orElse: () => widget.difficulty,
    );

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

    setState(() {
      _gameState = GameState(
        board: board,
        solution: solution,
        difficulty: difficulty,
        mistakes: data['mistakes'] ?? 0,
        hintsUsed: data['hintsUsed'] ?? 0,
        elapsed: Duration(seconds: data['elapsed'] ?? 0),
      );
      _isLoading = false;
    });
    _startTimer();
  }

  List<List<int>> _parse2DList(dynamic raw) {
    return (raw as List).map((row) =>
      (row as List).map((v) => v as int).toList()
    ).toList();
  }

  void _restartSamePuzzle() {
    final board = SudokuBoard.fromValues(_initialPuzzle);
    _persistentHighlightNumber = 0;
    setState(() {
      _gameState = GameState(
        board: board,
        solution: _currentSolution,
        difficulty: widget.difficulty,
      );
      _isPaused = false;
      _isTimerStopped = false;
      _drawingElements = [];
      _drawingMode = false;
    });
    _startTimer();
    _autoSave();
  }

  Future<void> _autoSave() async {
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

  bool get _isTimerRunning =>
      _gameState.status == GameStatus.playing &&
      !_isPaused &&
      !_isTimerStopped;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isTimerRunning) {
        setState(() {
          _gameState.elapsed += const Duration(seconds: 1);
        });
      }
    });
  }

  void _onMouseEnter(PointerEvent _) {
    if (_isTimerStopped) setState(() => _isTimerStopped = false);
  }

  void _onMouseExit(PointerEvent _) {
    if (!_isLoading &&
        _gameState.status == GameStatus.playing &&
        _settings.autoPauseOnLeave) {
      setState(() => _isTimerStopped = true);
    }
  }

  void _onCellTap((int, int) position) {
    if (_gameState.status != GameStatus.playing || _isPaused) return;
    final (row, col) = position;
    final isSameSelection =
        _gameState.selectedRow == row && _gameState.selectedCol == col;

    setState(() {
      if (isSameSelection) {
        _gameState.clearSelection();
        _persistentHighlightNumber = 0;
        return;
      }

      _gameState.selectCell(row, col);
      final tappedCell = _gameState.board.getCell(row, col);
      if (tappedCell.isFixed && tappedCell.value != 0) {
        _persistentHighlightNumber = tappedCell.value;
      }
    });
  }

  void _onNumberInput(int number) {
    if (_gameState.status != GameStatus.playing || _isPaused) return;
    if (!_gameState.hasSelection) return;

    final row = _gameState.selectedRow;
    final col = _gameState.selectedCol;
    final cell = _gameState.board.getCell(row, col);
    if (cell.isFixed) return;

    setState(() {
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
            _showGameOverDialog();
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
          _showWinDialog();
        }
      }
    });
    _autoSave();
  }

  void _onDelete() {
    if (_gameState.status != GameStatus.playing || _isPaused) return;
    if (!_gameState.hasSelection) return;
    final row = _gameState.selectedRow;
    final col = _gameState.selectedCol;
    setState(() {
      _gameState.saveSnapshot();
      _gameState.board.clearCell(row, col);
      _gameState.board.validateAll();
    });
    _autoSave();
  }

  void _onNotesToggle() {
    setState(() => _gameState.isNotesMode = !_gameState.isNotesMode);
  }

  /// Fill candidates for hint-involved cells AND their related groups.
  /// This ensures the next hint detection sees consistent candidate data.
  void _fillHintCandidates(TechniqueResult result) {
    final cellsToFill = <CellPosition>{
      ...result.highlightCells,
      ...result.relatedCells,
      ...result.eliminateCandidates.keys,
      ...result.placements.keys,
    };

    // Also fill cells in the same row/col/box as any elimination target,
    // so the next detection has a consistent view.
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
    // Same for placements
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

  /// Build a consistent candidate map for technique detection.
  /// Always starts from grid-computed candidates, then intersects with
  /// existing notes to preserve previous eliminations.
  List<List<Set<int>>> _getHintCandidates() {
    final grid = _gameState.board.toValues();
    return List.generate(9, (r) => List.generate(9, (c) {
      if (grid[r][c] != 0) return <int>{};
      final computed = _gameState.board.getCandidates(r, c);
      final cell = _gameState.board.getCell(r, c);
      if (cell.notes.isNotEmpty) {
        // Intersect: keep only candidates valid by grid AND not eliminated
        return computed.intersection(cell.notes);
      }
      return computed;
    }));
  }

  void _onHint() {
    if (_gameState.status != GameStatus.playing || _isPaused) return;

    final grid = _gameState.board.toValues();
    final candidates = _getHintCandidates();
    final result = HintService.getHintWithCandidates(grid, candidates);

    if (result != null) {
      setState(() {
        _showSmartHint = true;
        _hintStep2 = false;
        _hintResult = result;
        _hintBoardValues = grid;
        _hintBoardCandidates = candidates;
      });
      return;
    }

    // Fallback: direct answer reveal for the selected cell
    if (!_gameState.hasSelection) return;
    final row = _gameState.selectedRow;
    final col = _gameState.selectedCol;
    final cell = _gameState.board.getCell(row, col);
    if (cell.isFixed) return;

    setState(() {
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
        _showWinDialog();
      }
    });
    _autoSave();
  }

  void _applySmartHint() {
    if (_hintResult == null) return;

    setState(() {
      _gameState.saveSnapshot();
      _gameState.hintsUsed++;

      // Fill candidates only for cells involved in this hint
      _fillHintCandidates(_hintResult!);

      // Apply placements
      for (final entry in _hintResult!.placements.entries) {
        _gameState.board.setValue(
          entry.key.row, entry.key.col, entry.value,
          autoRemoveNotes: _settings.autoRemoveNotes,
        );
        _gameState.board.getCell(entry.key.row, entry.key.col).isError = false;
      }

      // Apply candidate eliminations
      for (final entry in _hintResult!.eliminateCandidates.entries) {
        final cell = _gameState.board.getCell(entry.key.row, entry.key.col);
        if (cell.notes.isEmpty && cell.isEmpty) {
          cell.notes = _gameState.board.getCandidates(entry.key.row, entry.key.col);
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
        _showWinDialog();
      }
    });
    _autoSave();
  }

  void _dismissSmartHint() {
    setState(() {
      _showSmartHint = false;
      _hintStep2 = false;
      _hintResult = null;
      _hintBoardValues = null;
      _hintBoardCandidates = null;
    });
  }

  void _onAutoNotes() {
    if (_gameState.status != GameStatus.playing || _isPaused) return;
    setState(() {
      _gameState.saveSnapshot();
      _gameState.board.fillAllCandidates();
    });
    _autoSave();
  }

  void _onUndo() {
    if (_gameState.status != GameStatus.playing || _isPaused) return;
    final snapshot = _gameState.popSnapshot();
    if (snapshot == null) return;
    setState(() {
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
    });
    _autoSave();
  }

  Set<int> _getActiveNotes() {
    if (!_gameState.isNotesMode || !_gameState.hasSelection) return const {};
    final cell = _gameState.board
        .getCell(_gameState.selectedRow, _gameState.selectedCol);
    if (cell.isFixed || cell.value != 0) return const {};
    return cell.notes;
  }

  void _toggleDrawingMode() {
    setState(() {
      _drawingMode = !_drawingMode;
      _drawingTool = _drawingMode ? DrawingTool.pen : DrawingTool.none;
    });
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('设置'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(title: const Text('自动删除候选数'), subtitle: const Text('填入数字时自动删除相关候选数'), value: _settings.autoRemoveNotes, onChanged: (v) { setDialogState(() => _settings.autoRemoveNotes = v); setState(() {}); }),
                const Divider(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('显示模式'),
                  subtitle: const Text('亮色、暗色或跟随系统'),
                ),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('亮色'),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('暗色'),
                      icon: Icon(Icons.dark_mode_outlined),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('系统'),
                      icon: Icon(Icons.brightness_auto_outlined),
                    ),
                  ],
                  selected: {widget.themeMode},
                  onSelectionChanged: (selection) {
                    widget.onThemeModeChanged(selection.first);
                    setDialogState(() {});
                  },
                ),
                const Divider(height: 20),
                SwitchListTile(title: const Text('高亮相同数字'), value: _settings.highlightSameNumbers, onChanged: (v) { setDialogState(() => _settings.highlightSameNumbers = v); setState(() {}); }),
                SwitchListTile(title: const Text('高亮关联区域'), subtitle: const Text('高亮选中格的同行、同列、同宫'), value: _settings.highlightRelatedCells, onChanged: (v) { setDialogState(() => _settings.highlightRelatedCells = v); setState(() {}); }),
                SwitchListTile(title: const Text('高亮候选数'), subtitle: const Text('选中数字时高亮匹配的候选数'), value: _settings.highlightCandidates, onChanged: (v) { setDialogState(() => _settings.highlightCandidates = v); setState(() {}); }),
                SwitchListTile(title: const Text('显示剩余数量'), value: _settings.showRemainingCount, onChanged: (v) { setDialogState(() => _settings.showRemainingCount = v); setState(() {}); }),
                SwitchListTile(title: const Text('显示计时器'), value: _settings.showTimer, onChanged: (v) { setDialogState(() => _settings.showTimer = v); setState(() {}); }),
                SwitchListTile(title: const Text('鼠标离开暂停计时'), subtitle: const Text('鼠标移出界面时暂停计时器，回来自动恢复'), value: _settings.autoPauseOnLeave, onChanged: (v) { setDialogState(() => _settings.autoPauseOnLeave = v); setState(() {}); }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () { _copyPuzzleString(); Navigator.of(ctx).pop(); }, child: const Text('复制题目')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('关闭')),
          ],
        ),
      ),
    );
  }

  void _copyPuzzleString() {
    final buf = StringBuffer();
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        buf.write(_initialPuzzle[r][c]);
      }
    }
    final text = buf.toString();
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('题目已复制：$text'), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('恭喜！'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.emoji_events, size: 64, color: AppTheme.accentColor),
          const SizedBox(height: 16),
          Text('难度：${_gameState.difficulty.name}'),
          Text('用时：${_formatDuration(_gameState.elapsed)}'),
          Text('错误：${_gameState.mistakes} 次'),
          Text('提示：${_gameState.hintsUsed} 次'),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.of(ctx).pop(); Navigator.of(context).pop(); }, child: const Text('返回首页')),
          ElevatedButton(onPressed: () { Navigator.of(ctx).pop(); _initGame(); }, child: const Text('再来一局')),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('游戏结束'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('错误已达 ${GameState.maxMistakes} 次上限'),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.of(ctx).pop(); Navigator.of(context).pop(); }, child: const Text('返回首页')),
          OutlinedButton(onPressed: () { Navigator.of(ctx).pop(); _restartSamePuzzle(); }, child: const Text('同题再做')),
          ElevatedButton(onPressed: () { Navigator.of(ctx).pop(); _initGame(); }, child: const Text('换题再来')),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.difficulty.name)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_gameState.difficulty.name),
        actions: [
          IconButton(icon: Icon(_drawingMode ? Icons.draw : Icons.draw_outlined), tooltip: '画图工具', onPressed: _toggleDrawingMode, color: _drawingMode ? AppTheme.primaryColor : null),
          IconButton(icon: const Icon(Icons.settings_outlined), tooltip: '设置', onPressed: _showSettingsDialog),
          IconButton(icon: const Icon(Icons.refresh), tooltip: '新游戏', onPressed: _initGame),
        ],
      ),
      body: MouseRegion(
        onEnter: _onMouseEnter,
        onExit: _onMouseExit,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(children: [
              _buildStatusBar(),
              const SizedBox(height: 8),
              if (_drawingMode && !_showSmartHint)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DrawingToolbar(
                      currentTool: _drawingTool, currentColor: _drawingColor,
                      onToolChanged: (t) => setState(() => _drawingTool = t),
                      onColorChanged: (c) => setState(() => _drawingColor = c),
                      onUndo: () { if (_drawingElements.isNotEmpty) setState(() { _drawingElements = List.from(_drawingElements)..removeLast(); }); },
                      onClear: () => setState(() => _drawingElements = []),
                    ),
                  ),
                ),
              Expanded(child: Center(
                child: _showSmartHint && _hintResult != null
                    ? _buildHintBoard()
                    : _buildBoardArea(),
              )),
              const SizedBox(height: 8),
              if (_showSmartHint && _hintResult != null)
                _buildHintControls()
              else if (!_isPaused)
                NumberPad(
                  onNumberTap: _onNumberInput, onDelete: _onDelete, onNotesToggle: _onNotesToggle,
                  onHint: _onHint, onUndo: _onUndo, onAutoNotes: _onAutoNotes,
                  isNotesMode: _gameState.isNotesMode,
                  remainingCounts: _settings.showRemainingCount ? _gameState.board.getRemainingCounts() : const {},
                  activeNotes: _getActiveNotes(),
                ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHintBoard() {
    return InteractiveTutorialBoard(
      boardValues: _hintBoardValues!,
      boardCandidates: _hintBoardCandidates!,
      techniqueResult: _hintResult!,
      showEliminations: _hintStep2,
    );
  }

  Widget _buildHintControls() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        children: [
          // Technique info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _hintResult!.type.nameZh,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _hintResult!.description,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _dismissSmartHint,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('关闭'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _hintStep2 ? _applySmartHint : () => setState(() => _hintStep2 = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_hintStep2 ? '应用此解法' : '下一步'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoardArea() {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.boardBackgroundOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Stack(children: [
        SudokuBoardWidget(gameState: _gameState, onCellTap: _onCellTap, highlightSameNumbers: _settings.highlightSameNumbers, highlightRelatedCells: _settings.highlightRelatedCells, highlightCandidates: _settings.highlightCandidates, persistentHighlightNumber: _persistentHighlightNumber),
        Positioned.fill(child: DrawingOverlay(isActive: _drawingMode, currentTool: _drawingTool, currentColor: _drawingColor, elements: _drawingElements, onElementsChanged: (e) => setState(() => _drawingElements = e))),
        if (_isPaused) _buildPauseOverlay(),
      ]),
    );
  }

  Widget _buildPauseOverlay() {
    final isDark = AppTheme.isDark(context);
    return Positioned.fill(
      child: GestureDetector(
        onTap: _togglePause,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xCC1E2530) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pause_circle_outline,
                  size: 64,
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500,
                ),
                const SizedBox(height: 16),
                Text(
                  '游戏已暂停',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFE2E8F0) : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击继续',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final timerIcon = (_isPaused || _isTimerStopped) ? Icons.play_arrow_rounded : Icons.pause_rounded;
    final timerColor = (_isPaused || _isTimerStopped) ? AppTheme.accentColor : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        if (_settings.showTimer) GestureDetector(onTap: _togglePause, child: _StatusItem(icon: timerIcon, label: _formatDuration(_gameState.elapsed), color: timerColor)),
        _StatusItem(icon: Icons.close, label: '${_gameState.mistakes}/${GameState.maxMistakes}', color: _gameState.mistakes > 0 ? AppTheme.errorColor : null),
        _StatusItem(icon: Icons.lightbulb_outline, label: '${_gameState.hintsUsed}'),
      ]),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _StatusItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final c = color ?? (isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700);
    return Row(children: [
      Icon(icon, size: 18, color: c),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c)),
    ]);
  }
}

class _GenerateResult {
  final List<List<int>> puzzleValues;
  final List<List<int>> solution;
  _GenerateResult({required this.puzzleValues, required this.solution});
}

_GenerateResult _generatePuzzle(Difficulty difficulty) {
  final generator = SudokuGenerator();
  final result = generator.generate(difficulty);
  return _GenerateResult(puzzleValues: result.puzzle.toValues(), solution: result.solution);
}
