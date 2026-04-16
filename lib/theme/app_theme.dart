import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF3F51B5);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF4CAF50);

  // Light palette (kept for existing references across codebase)
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

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color boardBackgroundOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF283240) : boardBackground;

  static Color cellBackgroundOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF202938) : cellBackground;

  static Color selectedCellColorOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF4E6798) : selectedCellColor;

  static Color highlightedCellColorOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF384558) : highlightedCellColor;

  static Color sameNumberHighlightOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF2F5B63) : sameNumberHighlight;

  static Color fixedTextColorOf(BuildContext context) =>
      isDark(context) ? const Color(0xFFF3F7FD) : fixedTextColor;

  static Color userTextColorOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF9FC5FF) : userTextColor;

  static Color notesTextColorOf(BuildContext context) =>
      isDark(context) ? const Color(0xFFC3D0E3) : notesTextColor;

  static Color gridLineColorOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF4A5568) : gridLineColor;

  static Color boxLineColorOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF94A3B8) : boxLineColor;

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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF171D27),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF252C38),
        titleTextStyle: TextStyle(
          color: Color(0xFFF2F5F8),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 14,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return const Color(0xFFCBD5E1);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.45);
          }
          return const Color(0xFF475569);
        }),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFFE2E8F0),
        iconColor: Color(0xFFE2E8F0),
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
        color: const Color(0xFF252C38),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
