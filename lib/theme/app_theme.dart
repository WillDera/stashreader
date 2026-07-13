import 'package:flutter/material.dart';

class AppTheme {
  // Accent
  static const Color accent = Color(0xFF0D7377);
  static const Color accentLight = Color(0xFF14A3A8);

  // Light mode
  static const Color lightBackground = Color(0xFFF5F2ED);
  static const Color lightSurface = Color(0xFFFFFFFA);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightBorder = Color(0xFFE0DDD7);

  // Dark mode
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF242424);
  static const Color darkText = Color(0xFFF5F2ED);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  static const Color darkBorder = Color(0xFF333333);

  static ThemeData lightTheme({
    String fontFamily = 'System',
    String? googleFont,
    double fontSize = 16.0,
    double lineHeight = 1.6,
  }) {
    final textTheme = _buildTextTheme(fontFamily, googleFont);
    final colorScheme = ColorScheme.light(
      primary: accent,
      secondary: accentLight,
      surface: lightSurface,
      onSurface: lightText,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: _resolveFont(fontFamily, googleFont),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightText,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorder, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: accent,
        unselectedItemColor: lightTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 0.5,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightBackground,
        side: const BorderSide(color: lightBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static ThemeData darkTheme({
    String fontFamily = 'System',
    String? googleFont,
    double fontSize = 16.0,
    double lineHeight = 1.6,
  }) {
    final textTheme = _buildTextTheme(fontFamily, googleFont);
    final colorScheme = ColorScheme.dark(
      primary: accent,
      secondary: accentLight,
      surface: darkSurface,
      onSurface: darkText,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: _resolveFont(fontFamily, googleFont),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: accent,
        unselectedItemColor: darkTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 0.5,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkBackground,
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static TextTheme _buildTextTheme(String fontFamily, String? googleFont) {
    final baseFont = _resolveFont(fontFamily, googleFont);
    return TextTheme(
      displayLarge: TextStyle(fontFamily: baseFont, fontWeight: FontWeight.w700),
      displayMedium: TextStyle(fontFamily: baseFont, fontWeight: FontWeight.w600),
      headlineLarge: TextStyle(fontFamily: baseFont, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontFamily: baseFont, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontFamily: baseFont, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontFamily: baseFont, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontFamily: baseFont, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontFamily: baseFont, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontFamily: baseFont, fontWeight: FontWeight.w500),
    );
  }

  static String _resolveFont(String fontFamily, String? googleFont) {
    if (googleFont != null && googleFont.isNotEmpty) {
      return googleFont;
    }
    return fontFamily;
  }
}
