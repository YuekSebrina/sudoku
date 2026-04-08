import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../models/technique.dart';
import '../models/tutorial_step.dart';
import '../services/storage_service.dart';
import '../services/sudoku_generator.dart';
import '../services/technique_finder.dart';
import '../theme/app_theme.dart';
import '../widgets/interactive_tutorial_board.dart';
import 'tutorial_practice_screen.dart';

/// Interactive tutorial screen: dynamically generates puzzles for the technique,
/// shows highlights immediately, and lets the user step through examples.
class TutorialDetailScreen extends StatefulWidget {
  final TutorialStep step;

  const TutorialDetailScreen({super.key, required this.step});

  @override
  State<TutorialDetailScreen> createState() => _TutorialDetailScreenState();
}

class _TutorialDetailScreenState extends State<TutorialDetailScreen> {
  int _currentIndex = 0;
  int _totalCompleted = 0;
  bool _isLoading = true;
  bool _applied = false;
  bool _showStep2 = false;
  bool _showDescription = true;

  late List<List<int>> _boardValues;
  late List<List<Set<int>>> _boardCandidates;
  late List<List<int>> _originalBoardValues;
  late List<List<Set<int>>> _originalBoardCandidates;
  TechniqueResult? _techniqueResult;
  TechniqueResult? _originalTechniqueResult;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _generatePuzzle();
  }

  Future<void> _loadProgress() async {
    final progress = await StorageService.loadPracticeProgress();
    final count = progress[widget.step.type.name] ?? 0;
    if (mounted) setState(() => _totalCompleted = count);
  }

  Future<void> _saveProgress() async {
    await StorageService.savePracticeProgress(widget.step.type.name, _totalCompleted);
  }

  Future<void> _generatePuzzle() async {
    setState(() {
      _isLoading = true;
      _applied = false;
      _showStep2 = false;
    });

    TechniqueResult? result;
    List<List<int>>? board;
    List<List<Set<int>>>? candidates;

    int attempts = 0;
    while (result == null && attempts < 50) {
      attempts++;
      try {
        final generator = SudokuGenerator();
        final difficulty = _difficultyForTechnique(widget.step.type);
        final genResult = generator.generate(difficulty);
        final grid = genResult.puzzle.toValues();
        final cands = TechniqueFinder.computeAllCandidates(grid);
        final simplified = _simplifyCandidates(grid, cands, widget.step.type);

        result = TechniqueFinder.findSpecific(
          widget.step.type, simplified.$1, simplified.$2,
        );
        if (result != null) {
          board = simplified.$1;
          candidates = simplified.$2;
        }
      } catch (_) {
        continue;
      }
    }

    if (result == null) {
      final generator = SudokuGenerator();
      final genResult = generator.generate(_difficultyForTechnique(widget.step.type));
      board = genResult.puzzle.toValues();
      candidates = TechniqueFinder.computeAllCandidates(board);
      result = TechniqueFinder.findNext(board, candidates);
    }

    if (mounted) {
      setState(() {
        _boardValues = board ?? List.generate(9, (_) => List.generate(9, (_) => 0));
        _boardCandidates = candidates ?? TechniqueFinder.computeAllCandidates(_boardValues);
        _techniqueResult = result;
        // Save originals for reset
        _originalBoardValues = List.generate(9, (r) => List<int>.from(_boardValues[r]));
        _originalBoardCandidates = List.generate(
          9, (r) => List.generate(9, (c) => Set<int>.from(_boardCandidates[r][c])),
        );
        _originalTechniqueResult = result;
        _isLoading = false;
      });
    }
  }

  (List<List<int>>, List<List<Set<int>>>) _simplifyCandidates(
    List<List<int>> grid,
    List<List<Set<int>>> candidates,
    TechniqueType target,
  ) {
    final g = List.generate(9, (r) => List<int>.from(grid[r]));
    final c = List.generate(
      9, (r) => List.generate(9, (col) => Set<int>.from(candidates[r][col])),
    );

    bool progress = true;
    int iterations = 0;
    while (progress && iterations < 200) {
      progress = false;
      iterations++;

      final targetResult = TechniqueFinder.findSpecific(target, g, c);
      if (targetResult != null) return (g, c);

      final nextResult = TechniqueFinder.findNext(g, c);
      if (nextResult == null) break;
      if (nextResult.type.weight >= target.weight) break;

      for (final entry in nextResult.placements.entries) {
        g[entry.key.row][entry.key.col] = entry.value;
        c[entry.key.row][entry.key.col].clear();
        _eliminateFromGrid(c, entry.key.row, entry.key.col, entry.value);
      }
      for (final entry in nextResult.eliminateCandidates.entries) {
        c[entry.key.row][entry.key.col].removeAll(entry.value);
      }
      progress = true;
    }
    return (g, c);
  }

  void _eliminateFromGrid(List<List<Set<int>>> cands, int row, int col, int val) {
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

  void _applyStep() {
    if (_techniqueResult == null) return;
    setState(() {
      _applied = true;
      for (final entry in _techniqueResult!.placements.entries) {
        _boardValues[entry.key.row][entry.key.col] = entry.value;
      }
      for (final entry in _techniqueResult!.eliminateCandidates.entries) {
        _boardCandidates[entry.key.row][entry.key.col].removeAll(entry.value);
      }
      _totalCompleted++;
    });
    _saveProgress();
  }

  void _nextPuzzle() {
    _currentIndex++;
    _generatePuzzle();
  }

  void _resetPuzzle() {
    setState(() {
      _applied = false;
      _showStep2 = false;
      _boardValues = List.generate(9, (r) => List<int>.from(_originalBoardValues[r]));
      _boardCandidates = List.generate(
        9, (r) => List.generate(9, (c) => Set<int>.from(_originalBoardCandidates[r][c])),
      );
      _techniqueResult = _originalTechniqueResult;
    });
  }

  void _goToPractice() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TutorialPracticeScreen(techniqueType: widget.step.type),
      ),
    );
  }

  static Difficulty _difficultyForTechnique(TechniqueType type) {
    switch (type.category) {
      case TechniqueCategory.beginner:
        return Difficulty.easy;
      case TechniqueCategory.intermediate:
        return Difficulty.medium;
      case TechniqueCategory.advanced:
        return Difficulty.hard;
      case TechniqueCategory.expert:
        return Difficulty.expert;
      case TechniqueCategory.chains:
        return Difficulty.extreme;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.step.title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('已完成 $_totalCompleted 题', style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在生成题目...'),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _categoryColor(widget.step.type.category).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.step.type.category.icon} ${widget.step.type.category.label}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _categoryColor(widget.step.type.category),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('第 ${_currentIndex + 1} 题',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton.icon(
                          icon: Icon(_showDescription ? Icons.visibility_off : Icons.visibility, size: 16),
                          label: Text(_showDescription ? '隐藏说明' : '显示说明'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () => setState(() => _showDescription = !_showDescription),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: InteractiveTutorialBoard(
                              boardValues: _boardValues,
                              boardCandidates: _boardCandidates,
                              techniqueResult: _applied ? null : _techniqueResult,
                              showEliminations: _showStep2,
                              originalValues: _originalBoardValues,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Technique description hint
                          if (!_applied && _techniqueResult != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _showStep2
                                    ? AppTheme.accentColor.withValues(alpha: 0.06)
                                    : AppTheme.primaryColor.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _showStep2
                                      ? AppTheme.accentColor.withValues(alpha: 0.2)
                                      : AppTheme.primaryColor.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _showStep2 ? Icons.auto_fix_high : Icons.lightbulb,
                                        size: 18,
                                        color: _showStep2
                                            ? AppTheme.accentColor
                                            : AppTheme.accentColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _showStep2 ? '第二步：观察变化' : '第一步：分析',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _showStep2
                                              ? AppTheme.accentColor
                                              : AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _techniqueResult!.description,
                                    style: const TextStyle(fontSize: 14, height: 1.5),
                                  ),
                                  if (_showStep2) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      _buildStep2Summary(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          if (_applied)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 20, color: AppTheme.successColor),
                                  SizedBox(width: 8),
                                  Text('已应用！候选数已更新。',
                                      style: TextStyle(fontSize: 14, color: AppTheme.successColor, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),

                          // Collapsible description
                          if (_showDescription) ...[
                            const SizedBox(height: 16),
                            ..._buildContentSections(widget.step.description),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: _applied ? _buildPostApplyButtons() : _buildApplyButton(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildApplyButton() {
    if (_showStep2) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('上一步', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => setState(() => _showStep2 = false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 18),
              label: const Text('应用此解法'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _applyStep,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: const Text('下一步'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => setState(() => _showStep2 = true),
      ),
    );
  }

  Widget _buildPostApplyButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.fitness_center, size: 16),
            label: const Text('练习题', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _goToPractice,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.skip_next, size: 16),
            label: const Text('下一道例题', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _nextPuzzle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重置', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _resetPuzzle,
          ),
        ),
      ],
    );
  }

  String _buildStep2Summary() {
    if (_techniqueResult == null) return '';
    final parts = <String>[];
    if (_techniqueResult!.placements.isNotEmpty) {
      for (final e in _techniqueResult!.placements.entries) {
        parts.add('R${e.key.row + 1}C${e.key.col + 1} 填入 ${e.value}');
      }
    }
    if (_techniqueResult!.eliminateCandidates.isNotEmpty) {
      final count = _techniqueResult!.eliminateCandidates.values
          .fold<int>(0, (sum, s) => sum + s.length);
      parts.add('删除 $count 个候选数');
    }
    return parts.isEmpty ? '' : '→ ${parts.join('，')}';
  }

  Color _categoryColor(TechniqueCategory category) {
    switch (category) {
      case TechniqueCategory.beginner:
        return AppTheme.successColor;
      case TechniqueCategory.intermediate:
        return AppTheme.primaryColor;
      case TechniqueCategory.advanced:
        return AppTheme.accentColor;
      case TechniqueCategory.expert:
        return AppTheme.errorColor;
      case TechniqueCategory.chains:
        return Colors.purple;
    }
  }

  List<Widget> _buildContentSections(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (trimmed.startsWith('【') && trimmed.endsWith('】')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(trimmed,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        ));
      } else if (trimmed.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('  •  ', style: TextStyle(fontSize: 14, color: AppTheme.primaryColor)),
              Expanded(child: Text(trimmed.substring(2), style: const TextStyle(fontSize: 14, height: 1.6))),
            ],
          ),
        ));
      } else if (RegExp(r'^\d+\. ').hasMatch(trimmed)) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(trimmed, style: const TextStyle(fontSize: 14, height: 1.6)),
        ));
      } else {
        widgets.add(Text(trimmed, style: const TextStyle(fontSize: 14, height: 1.6)));
      }
    }
    return widgets;
  }
}
