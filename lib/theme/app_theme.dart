import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF3F51B5);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF4CAF50);

  static const Color boardBackground = Color(0xFFF5F5F5);
  static const Color cellBackground = Colors.white;
  static const Color selectedCellColor = Color(0xFFBBDEFB);
  static const Color highlightedCellColor = Color(0xFFE3F2FD);
  static const Color sameNumberHighlight = Color(0xFFC8E6C9);
  static const Color fixedTextColor = Color(0xFF212121);
  static const Color userTextColor = Color(0xFF1565C0);
  static const Color errorTextColor = Color(0xFFE53935);
  static const Color notesTextColor = Color(0xFF757575);

  static const Color gridLineColor = Color(0xFFBDBDBD);
  static const Color boxLineColor = Color(0xFF212121);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
