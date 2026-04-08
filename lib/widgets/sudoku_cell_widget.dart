import 'package:flutter/material.dart';

import '../models/sudoku_cell.dart';
import '../theme/app_theme.dart';

class SudokuCellWidget extends StatelessWidget {
  final SudokuCell cell;
  final bool isSelected;
  final bool isHighlighted;
  final bool isSameNumber;
  final int highlightNumber;
  final VoidCallback onTap;

  const SudokuCellWidget({
    super.key,
    required this.cell,
    required this.isSelected,
    required this.isHighlighted,
    required this.isSameNumber,
    this.highlightNumber = 0,
    required this.onTap,
  });

  Color get _backgroundColor {
    if (isSelected) return AppTheme.selectedCellColor;
    if (isSameNumber) return AppTheme.sameNumberHighlight;
    if (isHighlighted) return AppTheme.highlightedCellColor;
    return AppTheme.cellBackground;
  }

  Color get _textColor {
    if (cell.isError) return AppTheme.errorTextColor;
    if (cell.isFixed) return AppTheme.fixedTextColor;
    return AppTheme.userTextColor;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border(
            top: BorderSide(
              color: cell.row % 3 == 0
                  ? AppTheme.boxLineColor
                  : AppTheme.gridLineColor,
              width: cell.row % 3 == 0 ? 2.0 : 1.0,
            ),
            left: BorderSide(
              color: cell.col % 3 == 0
                  ? AppTheme.boxLineColor
                  : AppTheme.gridLineColor,
              width: cell.col % 3 == 0 ? 2.0 : 1.0,
            ),
            bottom: BorderSide(
              color: cell.row == 8
                  ? AppTheme.boxLineColor
                  : Colors.transparent,
              width: cell.row == 8 ? 2.0 : 0,
            ),
            right: BorderSide(
              color: cell.col == 8
                  ? AppTheme.boxLineColor
                  : Colors.transparent,
              width: cell.col == 8 ? 2.0 : 0,
            ),
          ),
        ),
        child: Center(
          child: cell.value != 0
              ? Text(
                  '${cell.value}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        cell.isFixed ? FontWeight.bold : FontWeight.w500,
                    color: _textColor,
                  ),
                )
              : cell.notes.isNotEmpty
                  ? _buildNotes()
                  : null,
        ),
      ),
    );
  }

  Widget _buildNotes() {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Column(
        children: List.generate(3, (row) {
          return Expanded(
            child: Row(
              children: List.generate(3, (col) {
                final number = row * 3 + col + 1;
                final hasNote = cell.notes.contains(number);
                final isHL = hasNote && highlightNumber == number;
                return Expanded(
                  child: Container(
                    decoration: isHL
                        ? BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(3),
                          )
                        : null,
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        hasNote ? '$number' : '',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isHL ? FontWeight.bold : FontWeight.normal,
                          color: isHL ? AppTheme.primaryColor : AppTheme.notesTextColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
