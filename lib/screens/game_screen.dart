import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/game_view_controller.dart';
import '../models/difficulty.dart';
import '../models/drawing.dart';
import '../models/game_state.dart';
import '../models/technique.dart';
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
  late final GameViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameViewController();
    if (widget.savedGame != null) {
      _controller.loadSavedGame(widget.savedGame!, widget.difficulty);
    } else {
      _controller.initGame(widget.difficulty);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                SwitchListTile(
                    title: const Text('自动删除候选数'),
                    subtitle: const Text('填入数字时自动删除相关候选数'),
                    value: _controller.settings.autoRemoveNotes,
                    onChanged: (v) {
                      setDialogState(
                          () => _controller.settings.autoRemoveNotes = v);
                      setState(() {});
                    }),
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
                SwitchListTile(
                    title: const Text('高亮相同数字'),
                    value: _controller.settings.highlightSameNumbers,
                    onChanged: (v) {
                      setDialogState(
                          () => _controller.settings.highlightSameNumbers = v);
                      setState(() {});
                    }),
                SwitchListTile(
                    title: const Text('高亮关联区域'),
                    subtitle: const Text('高亮选中格的同行、同列、同宫'),
                    value: _controller.settings.highlightRelatedCells,
                    onChanged: (v) {
                      setDialogState(() =>
                          _controller.settings.highlightRelatedCells = v);
                      setState(() {});
                    }),
                SwitchListTile(
                    title: const Text('高亮候选数'),
                    subtitle: const Text('选中数字时高亮匹配的候选数'),
                    value: _controller.settings.highlightCandidates,
                    onChanged: (v) {
                      setDialogState(
                          () => _controller.settings.highlightCandidates = v);
                      setState(() {});
                    }),
                SwitchListTile(
                    title: const Text('显示剩余数量'),
                    value: _controller.settings.showRemainingCount,
                    onChanged: (v) {
                      setDialogState(
                          () => _controller.settings.showRemainingCount = v);
                      setState(() {});
                    }),
                SwitchListTile(
                    title: const Text('显示计时器'),
                    value: _controller.settings.showTimer,
                    onChanged: (v) {
                      setDialogState(
                          () => _controller.settings.showTimer = v);
                      setState(() {});
                    }),
                SwitchListTile(
                    title: const Text('鼠标离开暂停计时'),
                    subtitle: const Text('鼠标移出界面时暂停计时器，回来自动恢复'),
                    value: _controller.settings.autoPauseOnLeave,
                    onChanged: (v) {
                      setDialogState(
                          () => _controller.settings.autoPauseOnLeave = v);
                      setState(() {});
                    }),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  _copyPuzzleString();
                  Navigator.of(ctx).pop();
                },
                child: const Text('复制题目')),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('关闭')),
          ],
        ),
      ),
    );
  }

  void _copyPuzzleString() {
    // Access initial puzzle through the game state board
    final values = _controller.gameState.board.toValues();
    final buf = StringBuffer();
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        buf.write(values[r][c]);
      }
    }
    final text = buf.toString();
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('题目已复制：$text'),
            duration: const Duration(seconds: 2)),
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
          const Icon(Icons.emoji_events,
              size: 64, color: AppTheme.accentColor),
          const SizedBox(height: 16),
          Text('难度：${_controller.gameState.difficulty.name}'),
          Text(
              '用时：${_controller.formatDuration(_controller.gameState.elapsed)}'),
          Text('错误：${_controller.gameState.mistakes} 次'),
          Text('提示：${_controller.gameState.hintsUsed} 次'),
        ]),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('返回首页')),
          ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _controller.initGame(widget.difficulty);
              },
              child: const Text('再来一局')),
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
          Icon(Icons.sentiment_dissatisfied,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('错误已达 ${GameState.maxMistakes} 次上限'),
        ]),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('返回首页')),
          OutlinedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _controller.restartSamePuzzle();
              },
              child: const Text('同题再做')),
          ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _controller.initGame(widget.difficulty);
              },
              child: const Text('换题再来')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        // Show dialogs based on game state
        if (_controller.isLost) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showGameOverDialog();
          });
        } else if (_controller.isWon) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showWinDialog();
          });
        }

        if (_controller.isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.difficulty.name)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_controller.gameState.difficulty.name),
            actions: [
              IconButton(
                  icon: Icon(_controller.drawingMode
                      ? Icons.draw
                      : Icons.draw_outlined),
                  tooltip: '画图工具',
                  onPressed: _controller.toggleDrawingMode,
                  color: _controller.drawingMode
                      ? AppTheme.primaryColor
                      : null),
              IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: '设置',
                  onPressed: _showSettingsDialog),
              IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '新游戏',
                  onPressed: () =>
                      _controller.initGame(widget.difficulty)),
            ],
          ),
          body: MouseRegion(
            onEnter: (_) => _controller.onMouseEnter(),
            onExit: (_) => _controller.onMouseExit(),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(children: [
                  _buildStatusBar(),
                  const SizedBox(height: 8),
                  if (_controller.drawingMode &&
                      !_controller.showSmartHint)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DrawingToolbar(
                          currentTool: _controller.drawingTool,
                          currentColor: _controller.drawingColor,
                          onToolChanged: _controller.setDrawingTool,
                          onColorChanged: _controller.setDrawingColor,
                          onUndo: _controller.undoDrawing,
                          onClear: _controller.clearDrawing,
                        ),
                      ),
                    ),
                  Expanded(
                      child: Center(
                    child: _controller.showSmartHint &&
                            _controller.hintResult != null
                        ? _buildHintBoard()
                        : _buildBoardArea(),
                  )),
                  const SizedBox(height: 8),
                  if (_controller.showSmartHint &&
                      _controller.hintResult != null)
                    _buildHintControls()
                  else if (!_controller.isPaused)
                    NumberPad(
                      onNumberTap: _controller.onNumberInput,
                      onDelete: _controller.onDelete,
                      onNotesToggle: _controller.onNotesToggle,
                      onHint: _controller.onHint,
                      onUndo: _controller.onUndo,
                      onAutoNotes: _controller.onAutoNotes,
                      isNotesMode:
                          _controller.gameState.isNotesMode,
                      remainingCounts:
                          _controller.settings.showRemainingCount
                              ? _controller.gameState.board
                                  .getRemainingCounts()
                              : const {},
                      activeNotes: _controller.getActiveNotes(),
                    ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHintBoard() {
    return InteractiveTutorialBoard(
      boardValues: _controller.hintBoardValues!,
      boardCandidates: _controller.hintBoardCandidates!,
      techniqueResult: _controller.hintResult!,
      showEliminations: _controller.hintStep2,
    );
  }

  Widget _buildHintControls() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _controller.hintResult!.type.nameZh,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _controller.hintResult!.description,
                    style:
                        const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _controller.dismissSmartHint,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('关闭'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _controller.hintStep2
                      ? _controller.applySmartHint
                      : () => _controller.setHintStep2(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                      _controller.hintStep2 ? '应用此解法' : '下一步'),
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
                  color: AppTheme.primaryColor
                      .withValues(alpha: 0.08),
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
        SudokuBoardWidget(
          gameState: _controller.gameState,
          onCellTap: _controller.onCellTap,
          highlightSameNumbers:
              _controller.settings.highlightSameNumbers,
          highlightRelatedCells:
              _controller.settings.highlightRelatedCells,
          highlightCandidates:
              _controller.settings.highlightCandidates,
          persistentHighlightNumber:
              _controller.persistentHighlightNumber,
        ),
        Positioned.fill(
            child: DrawingOverlay(
          isActive: _controller.drawingMode,
          currentTool: _controller.drawingTool,
          currentColor: _controller.drawingColor,
          elements: _controller.drawingElements,
          onElementsChanged: _controller.setDrawingElements,
        )),
        if (_controller.isPaused) _buildPauseOverlay(),
      ]),
    );
  }

  Widget _buildPauseOverlay() {
    final isDark = AppTheme.isDark(context);
    return Positioned.fill(
      child: GestureDetector(
        onTap: _controller.togglePause,
        child: Container(
          decoration: BoxDecoration(
            color:
                isDark ? const Color(0xCC1E2530) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pause_circle_outline,
                  size: 64,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : Colors.grey.shade500,
                ),
                const SizedBox(height: 16),
                Text(
                  '游戏已暂停',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击继续',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : Colors.grey.shade500,
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
    final gs = _controller.gameState;
    final timerIcon = (_controller.isPaused || _controller.isTimerStopped)
        ? Icons.play_arrow_rounded
        : Icons.pause_rounded;
    final timerColor =
        (_controller.isPaused || _controller.isTimerStopped)
            ? AppTheme.accentColor
            : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        if (_controller.settings.showTimer)
          GestureDetector(
              onTap: _controller.togglePause,
              child: _StatusItem(
                  icon: timerIcon,
                  label: _controller.formatDuration(gs.elapsed),
                  color: timerColor)),
        _StatusItem(
            icon: Icons.close,
            label: '${gs.mistakes}/${GameState.maxMistakes}',
            color: gs.mistakes > 0 ? AppTheme.errorColor : null),
        _StatusItem(icon: Icons.lightbulb_outline, label: '${gs.hintsUsed}'),
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
      Text(label,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: c)),
    ]);
  }
}
