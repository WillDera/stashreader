import 'package:flutter/material.dart';

class AppTheme {
  // Accent — warm terracotta
  static const Color accent = Color(0xFFC4734F);
  static const Color accentLight = Color(0xFFD4936F);

  // Light mode
  static const Color lightBackground = Color(0xFFF8F6F0);
  static const Color lightSurface = Color(0xFFFFFCF7);
  static const Color lightText = Color(0xFF2C2C2C);
  static const Color lightTextSecondary = Color(0xFF8B8B8B);
  static const Color lightBorder = Color(0xFFEBE7DE);

  // Dark mode
  static const Color darkBackground = Color(0xFF1C1B1A);
  static const Color darkSurface = Color(0xFF282725);
  static const Color darkText = Color(0xFFE8E4DE);
  static const Color darkTextSecondary = Color(0xFF9A9690);
  static const Color darkBorder = Color(0xFF3A3835);

  // Sepia mode
  static const Color sepiaBackground = Color(0xFFF5EBD9);
  static const Color sepiaSurface = Color(0xFFFBF3E8);
  static const Color sepiaText = Color(0xFF5C4A3A);
  static const Color sepiaTextSecondary = Color(0xFF8A7A6A);
  static const Color sepiaBorder = Color(0xFFE4D5C0);
  static const Color sepiaAccent = Color(0xFFB8774A);

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
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: _resolveFont(fontFamily, googleFont),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: lightText,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 3,
        shadowColor: const Color(0x26000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: _resolveFont(fontFamily, googleFont),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 3,
        shadowColor: const Color(0x26000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // ponytail: sepia theme duplicates a lot from lightTheme — acceptable for 3 distinct palettes, refactor to shared helper if adding a 4th
  static ThemeData sepiaTheme({
    String fontFamily = 'System',
    String? googleFont,
    double fontSize = 16.0,
    double lineHeight = 1.6,
  }) {
    final textTheme = _buildTextTheme(fontFamily, googleFont);
    final colorScheme = ColorScheme.light(
      primary: sepiaAccent,
      secondary: accentLight,
      surface: sepiaSurface,
      onSurface: sepiaText,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: sepiaBackground,
      fontFamily: _resolveFont(fontFamily, googleFont),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: sepiaText,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: sepiaSurface,
        elevation: 3,
        shadowColor: const Color(0x1A000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: sepiaSurface,
        selectedItemColor: sepiaAccent,
        unselectedItemColor: sepiaTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: sepiaAccent,
        foregroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: sepiaBorder,
        thickness: 0.5,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: sepiaBackground,
        side: const BorderSide(color: sepiaBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sepiaSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: sepiaBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: sepiaBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: sepiaAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
