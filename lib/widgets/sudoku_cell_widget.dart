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

  Color _backgroundColor(BuildContext context) {
    if (isSelected) return AppTheme.selectedCellColorOf(context);
    if (isSameNumber) return AppTheme.sameNumberHighlightOf(context);
    if (isHighlighted) return AppTheme.highlightedCellColorOf(context);
    return AppTheme.cellBackgroundOf(context);
  }

  Color _textColor(BuildContext context) {
    if (cell.isError) return AppTheme.errorColor;
    if (cell.isFixed) return AppTheme.fixedTextColorOf(context);
    return AppTheme.userTextColorOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor(context),
          borderRadius: BorderRadius.circular(2),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: isSelected ? 8 : 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
          border: isSelected
              ? Border.all(
                  color: AppTheme.primaryColor.withValues(
                    alpha: isDark ? 0.95 : 0.55,
                  ),
                  width: 1.6,
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: cell.row % 3 == 0
                    ? AppTheme.boxLineColorOf(context)
                    : AppTheme.gridLineColorOf(context),
                width: cell.row % 3 == 0 ? 2.0 : 1.0,
              ),
              left: BorderSide(
                color: cell.col % 3 == 0
                    ? AppTheme.boxLineColorOf(context)
                    : AppTheme.gridLineColorOf(context),
                width: cell.col % 3 == 0 ? 2.0 : 1.0,
              ),
              bottom: BorderSide(
                color: cell.row == 8
                    ? AppTheme.boxLineColorOf(context)
                    : Colors.transparent,
                width: cell.row == 8 ? 2.0 : 0,
              ),
              right: BorderSide(
                color: cell.col == 8
                    ? AppTheme.boxLineColorOf(context)
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
                      color: _textColor(context),
                    ),
                  )
                : cell.notes.isNotEmpty
                    ? _buildNotes(context, isDark)
                    : null,
          ),
        ),
      ),
    );
  }

  Widget _buildNotes(BuildContext context, bool isDark) {
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
                            color: AppTheme.primaryColor.withValues(
                              alpha: isDark ? 0.62 : 0.25,
                            ),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: isDark ? 0.95 : 0.45,
                              ),
                              width: isDark ? 1.0 : 0.6,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          )
                        : null,
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        hasNote ? '$number' : '',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isHL ? FontWeight.w800 : FontWeight.w600,
                          color: isHL
                              ? (isDark
                                  ? const Color(0xFFF7FBFF)
                                  : AppTheme.primaryColor)
                              : AppTheme.notesTextColorOf(context),
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
