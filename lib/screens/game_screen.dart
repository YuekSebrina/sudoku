import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/difficulty.dart';
import '../models/drawing.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../models/sudoku_board.dart';
import '../services/storage_service.dart';
import '../services/sudoku_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/drawing_overlay.dart';
import '../widgets/drawing_toolbar.dart';
import '../widgets/number_pad.dart';
import '../widgets/sudoku_board_widget.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final Map<String, dynamic>? savedGame;

  const GameScreen({super.key, required this.difficulty, this.savedGame});

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
  late List<List<int>> _initialPuzzle;
  late List<List<int>> _currentSolution;

  bool _drawingMode = false;
  DrawingTool _drawingTool = DrawingTool.pen;
  Color _drawingColor = const Color(0xFFE53935);
  List<DrawingElement> _drawingElements = [];

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

    final result = await compute(_generatePuzzle, widget.difficulty);

    _initialPuzzle = result.puzzleValues;
    _currentSolution = result.solution;

    setState(() {
      _gameState = GameState(
        board: SudokuBoard.fromValues(result.puzzleValues),
        solution: result.solution,
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
    setState(() => _gameState.selectCell(row, col));
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
          if (_gameState.mistakes >= GameState.maxMistakes) {
            _gameState.status = GameStatus.completed;
            _timer?.cancel();
            StorageService.clearGame();
            StorageService.recordLoss(_gameState.difficulty.name);
            _showGameOverDialog();
          }
        } else {
          cell.isError = false;
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

  void _onHint() {
    if (_gameState.status != GameStatus.playing || _isPaused) return;
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
              if (_drawingMode)
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
              Expanded(child: Center(child: _buildBoardArea())),
              const SizedBox(height: 8),
              if (!_isPaused)
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

  Widget _buildBoardArea() {
    return Stack(children: [
      SudokuBoardWidget(gameState: _gameState, onCellTap: _onCellTap, highlightSameNumbers: _settings.highlightSameNumbers, highlightRelatedCells: _settings.highlightRelatedCells, highlightCandidates: _settings.highlightCandidates),
      Positioned.fill(child: DrawingOverlay(isActive: _drawingMode, currentTool: _drawingTool, currentColor: _drawingColor, elements: _drawingElements, onElementsChanged: (e) => setState(() => _drawingElements = e))),
      if (_isPaused) _buildPauseOverlay(),
    ]);
  }

  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _togglePause,
        child: Container(
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.pause_circle_outline, size: 64, color: Colors.grey.shade500),
            const SizedBox(height: 16),
            Text('游戏已暂停', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('点击继续', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ])),
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
    final c = color ?? Colors.grey.shade700;
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
