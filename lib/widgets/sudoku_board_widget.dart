import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../theme/app_theme.dart';
import 'sudoku_cell_widget.dart';

class SudokuBoardWidget extends StatelessWidget {
  final GameState gameState;
  final ValueChanged<(int, int)> onCellTap;
  final bool highlightSameNumbers;
  final bool highlightRelatedCells;
  final bool highlightCandidates;
  final int persistentHighlightNumber;

  const SudokuBoardWidget({
    super.key,
    required this.gameState,
    required this.onCellTap,
    this.highlightSameNumbers = true,
    this.highlightRelatedCells = true,
    this.highlightCandidates = true,
    this.persistentHighlightNumber = 0,
  });

  bool _isHighlighted(int row, int col) {
    if (!highlightRelatedCells) return false;
    if (!gameState.hasSelection) return false;
    final sr = gameState.selectedRow;
    final sc = gameState.selectedCol;
    if (row == sr || col == sc) return true;
    if ((row ~/ 3 == sr ~/ 3) && (col ~/ 3 == sc ~/ 3)) return true;
    return false;
  }

  int get _effectiveHighlightNumber {
    if (!gameState.hasSelection) return persistentHighlightNumber;
    final selectedCell = gameState.board.getCell(
      gameState.selectedRow,
      gameState.selectedCol,
    );
    if (selectedCell.value != 0) return selectedCell.value;
    return persistentHighlightNumber;
  }

  bool _isSameNumber(int row, int col) {
    if (!highlightSameNumbers) return false;
    final number = _effectiveHighlightNumber;
    if (number == 0) return false;
    final current = gameState.board.getCell(row, col);
    return current.value == number && current.value != 0;
  }

  int get _selectedNumber {
    if (!highlightCandidates) return 0;
    return _effectiveHighlightNumber;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.boxLineColorOf(context), width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
            ),
            itemCount: 81,
            itemBuilder: (context, index) {
              final row = index ~/ 9;
              final col = index % 9;
              final cell = gameState.board.getCell(row, col);
              final isSelected = row == gameState.selectedRow &&
                  col == gameState.selectedCol;

              return SudokuCellWidget(
                cell: cell,
                isSelected: isSelected,
                isHighlighted: _isHighlighted(row, col),
                isSameNumber: _isSameNumber(row, col),
                highlightNumber: _selectedNumber,
                onTap: () => onCellTap((row, col)),
              );
            },
          ),
        ),
      ),
    );
  }
}
