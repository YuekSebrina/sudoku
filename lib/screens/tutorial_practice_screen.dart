import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../models/technique.dart';
import '../services/storage_service.dart';
import '../services/sudoku_generator.dart';
import '../services/technique_finder.dart';
import '../theme/app_theme.dart';
import '../widgets/interactive_tutorial_board.dart';

/// Practice screen with interactive board: user can tap cells, input numbers,
/// and eliminate candidates to practice finding and applying a technique.
class TutorialPracticeScreen extends StatefulWidget {
  final TechniqueType techniqueType;

  const TutorialPracticeScreen({super.key, required this.techniqueType});

  @override
  State<TutorialPracticeScreen> createState() => _TutorialPracticeScreenState();
}

class _TutorialPracticeScreenState extends State<TutorialPracticeScreen> {
  int _currentIndex = 0;
  int _totalCompleted = 0;
  bool _isLoading = true;
  bool _showHint = false;
  bool _applied = false;
  bool _isNotesMode = false;
  CellPosition? _selectedCell;

  late List<List<int>> _boardValues;
  late List<List<Set<int>>> _boardCandidates;
  late List<List<int>> _originalBoardValues;
  late List<List<Set<int>>> _originalBoardCandidates;
  TechniqueResult? _techniqueResult;

  // Track user's own eliminations for verification
  final Map<CellPosition, Set<int>> _userEliminations = {};
  final Map<CellPosition, int> _userPlacements = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _generatePuzzle();
  }

  Future<void> _loadProgress() async {
    final progress = await StorageService.loadPracticeProgress();
    final count = progress[widget.techniqueType.name] ?? 0;
    if (mounted) setState(() => _totalCompleted = count);
  }

  Future<void> _saveProgress() async {
    await StorageService.savePracticeProgress(widget.techniqueType.name, _totalCompleted);
  }

  Future<void> _generatePuzzle() async {
    setState(() {
      _isLoading = true;
      _showHint = false;
      _applied = false;
      _selectedCell = null;
      _isNotesMode = false;
      _userEliminations.clear();
      _userPlacements.clear();
    });

    TechniqueResult? result;
    List<List<int>>? board;
    List<List<Set<int>>>? candidates;

    int attempts = 0;
    while (result == null && attempts < 50) {
      attempts++;
      try {
        final generator = SudokuGenerator();
        final difficulty = _difficultyForTechnique(widget.techniqueType);
        final genResult = generator.generate(difficulty);
        final grid = genResult.puzzle.toValues();
        final cands = TechniqueFinder.computeAllCandidates(grid);
        final simplified = _simplifyCandidates(grid, cands, widget.techniqueType);

        result = TechniqueFinder.findSpecific(
          widget.techniqueType, simplified.$1, simplified.$2,
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
      final genResult = generator.generate(_difficultyForTechnique(widget.techniqueType));
      board = genResult.puzzle.toValues();
      candidates = TechniqueFinder.computeAllCandidates(board);
      result = TechniqueFinder.findNext(board, candidates);
    }

    if (mounted) {
      setState(() {
        _boardValues = board ?? List.generate(9, (_) => List.generate(9, (_) => 0));
        _boardCandidates = candidates ?? TechniqueFinder.computeAllCandidates(_boardValues);
        _originalBoardValues = List.generate(9, (r) => List<int>.from(_boardValues[r]));
        _originalBoardCandidates = List.generate(
          9, (r) => List.generate(9, (c) => Set<int>.from(_boardCandidates[r][c])),
        );
        _techniqueResult = result;
        _isLoading = false;
      });
    }
  }

  (List<List<int>>, List<List<Set<int>>>) _simplifyCandidates(
    List<List<int>> grid, List<List<Set<int>>> candidates, TechniqueType target,
  ) {
    final g = List.generate(9, (r) => List<int>.from(grid[r]));
    final c = List.generate(9, (r) => List.generate(9, (col) => Set<int>.from(candidates[r][col])));

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

  void _onCellTap(CellPosition pos) {
    setState(() {
      _selectedCell = (_selectedCell == pos) ? null : pos;
    });
  }

  void _onNumberInput(int number) {
    if (_selectedCell == null || _applied) return;
    final row = _selectedCell!.row, col = _selectedCell!.col;
    if (_originalBoardValues[row][col] != 0) return; // fixed cell

    setState(() {
      if (_isNotesMode) {
        // Toggle candidate elimination
        final pos = _selectedCell!;
        _userEliminations.putIfAbsent(pos, () => {});
        if (_userEliminations[pos]!.contains(number)) {
          _userEliminations[pos]!.remove(number);
          // Restore the candidate
          _boardCandidates[row][col].add(number);
        } else {
          _userEliminations[pos]!.add(number);
          // Remove the candidate visually
          _boardCandidates[row][col].remove(number);
        }
        if (_userEliminations[pos]!.isEmpty) _userEliminations.remove(pos);
      } else {
        // Place a number
        final pos = _selectedCell!;
        if (_boardValues[row][col] == number) {
          // Un-place
          _boardValues[row][col] = 0;
          _userPlacements.remove(pos);
          // Restore candidates
          _boardCandidates[row][col] = Set<int>.from(_originalBoardCandidates[row][col]);
        } else {
          _boardValues[row][col] = number;
          _userPlacements[pos] = number;
          _boardCandidates[row][col].clear();
        }
      }
    });
  }

  void _onDelete() {
    if (_selectedCell == null || _applied) return;
    final row = _selectedCell!.row, col = _selectedCell!.col;
    if (_originalBoardValues[row][col] != 0) return;

    setState(() {
      final pos = _selectedCell!;
      _boardValues[row][col] = 0;
      _userPlacements.remove(pos);
      _userEliminations.remove(pos);
      _boardCandidates[row][col] = Set<int>.from(_originalBoardCandidates[row][col]);
    });
  }

  void _verify() {
    if (_techniqueResult == null) return;

    // Check if user's actions match the expected technique
    bool correct = true;

    // Check placements
    for (final entry in _techniqueResult!.placements.entries) {
      if (_userPlacements[entry.key] != entry.value) {
        correct = false;
        break;
      }
    }

    // Check eliminations
    if (correct) {
      for (final entry in _techniqueResult!.eliminateCandidates.entries) {
        final userElim = _userEliminations[entry.key] ?? {};
        if (!userElim.containsAll(entry.value)) {
          correct = false;
          break;
        }
      }
    }

    if (correct) {
      setState(() {
        _applied = true;
        _selectedCell = null;
        _totalCompleted++;
      });
      _saveProgress();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正确！'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('还不正确，再试试看'),
          backgroundColor: AppTheme.accentColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _applyAnswer() {
    if (_techniqueResult == null) return;
    setState(() {
      _applied = true;
      _selectedCell = null;
      // Reset to original and apply correct answer
      _boardValues = List.generate(9, (r) => List<int>.from(_originalBoardValues[r]));
      _boardCandidates = List.generate(
        9, (r) => List.generate(9, (c) => Set<int>.from(_originalBoardCandidates[r][c])),
      );
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
        title: Text(widget.techniqueType.nameZh),
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
                  Text('正在生成练习题...'),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Text('第 ${_currentIndex + 1} 题',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(widget.techniqueType.category.label,
                              style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  // Board - always show region borders, only show cell highlights after hint
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: InteractiveTutorialBoard(
                          boardValues: _boardValues,
                          boardCandidates: _boardCandidates,
                          techniqueResult: _showHint || _applied ? _techniqueResult : null,
                          showEliminations: false,
                          selectedCell: _selectedCell,
                          onCellTap: _applied ? null : _onCellTap,
                          regions: _techniqueResult != null
                              ? computeRegionsForTechnique(_techniqueResult!)
                              : null,
                          originalValues: _originalBoardValues,
                        ),
                      ),
                    ),
                  ),

                  // Selected cell info
                  if (_selectedCell != null && !_applied)
                    _buildSelectedCellInfo(),

                  // Hint description
                  if (_showHint && _techniqueResult != null && !_applied)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                        ),
                        child: Text(_techniqueResult!.description,
                            style: const TextStyle(fontSize: 13, height: 1.4)),
                      ),
                    ),

                  // Success
                  if (_applied)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 20, color: AppTheme.successColor),
                            SizedBox(width: 8),
                            Text('技巧已应用！',
                                style: TextStyle(fontSize: 14, color: AppTheme.successColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),

                  // Number pad + actions
                  if (!_applied) ...[
                    _buildNumberPad(),
                    const SizedBox(height: 8),
                    _buildActionButtons(),
                  ] else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('下一题'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _nextPuzzle,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectedCellInfo() {
    final row = _selectedCell!.row, col = _selectedCell!.col;
    final value = _boardValues[row][col];
    final cands = _boardCandidates[row][col];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.highlightedCellColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text('R${row + 1}C${col + 1}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(width: 12),
            if (value != 0)
              Text('值: $value', style: const TextStyle(fontSize: 13))
            else if (cands.isNotEmpty)
              Expanded(
                child: Text('候选: ${(cands.toList()..sort()).join(" ")}',
                    style: const TextStyle(fontSize: 13)),
              )
            else
              const Text('空', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Number row
          Row(
            children: List.generate(9, (i) {
              final number = i + 1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onNumberInput(number),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$number',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Tool row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolBtn(Icons.backspace_outlined, '擦除', _onDelete),
              _buildToolBtn(
                Icons.edit_outlined,
                _isNotesMode ? '笔记 ON' : '笔记',
                () => setState(() => _isNotesMode = !_isNotesMode),
                isActive: _isNotesMode,
              ),
              _buildToolBtn(Icons.lightbulb_outline, '提示', () => setState(() => _showHint = true)),
              _buildToolBtn(Icons.check_circle_outline, '验证', _verify,
                  color: AppTheme.successColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolBtn(IconData icon, String label, VoidCallback onTap,
      {bool isActive = false, Color? color}) {
    final c = color ?? (isActive ? AppTheme.primaryColor : Colors.grey.shade600);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryColor.withValues(alpha: 0.12)
                      : Colors.grey.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? AppTheme.primaryColor : Colors.grey.shade200,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Icon(icon, color: c, size: 18),
              ),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: c)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          if (_showHint)
            Expanded(
              child: ElevatedButton(
                onPressed: _applyAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('直接应用', style: TextStyle(fontSize: 13)),
              ),
            ),
          if (_showHint) const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: _nextPuzzle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('跳过', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
