import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const _keyThemeMode = 'theme_mode';
  static const _keyFontFamily = 'font_family';
  static const _keyGoogleFont = 'google_font';
  static const _keyFontSize = 'font_size';
  static const _keyLineHeight = 'line_height';
  ThemeMode _themeMode = ThemeMode.system;
  String _fontFamily = 'System';
  String? _googleFont;
  double _fontSize = 16.0;
  double _lineHeight = 1.6;
  Color _bgColor = AppTheme.lightBackground;

  ThemeMode get themeMode => _themeMode;
  String get fontFamily => _fontFamily;
  String? get googleFont => _googleFont;
  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  Color get bgColor => _bgColor;

  bool get isDark => _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  ThemeData get lightTheme => AppTheme.lightTheme(
        fontFamily: _fontFamily,
        googleFont: _googleFont,
        fontSize: _fontSize,
        lineHeight: _lineHeight,
      );

  ThemeData get darkTheme => AppTheme.darkTheme(
        fontFamily: _fontFamily,
        googleFont: _googleFont,
        fontSize: _fontSize,
        lineHeight: _lineHeight,
      );

  ThemeData get currentTheme => isDark ? darkTheme : lightTheme;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt(_keyThemeMode) ?? 0];
    _fontFamily = prefs.getString(_keyFontFamily) ?? 'System';
    final fontStr = prefs.getString(_keyGoogleFont);
    _googleFont = fontStr?.isNotEmpty == true ? fontStr : null;
    _fontSize = prefs.getDouble(_keyFontSize) ?? 16.0;
    _lineHeight = prefs.getDouble(_keyLineHeight) ?? 1.6;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFontFamily, family);
  }

  Future<void> setGoogleFont(String? font) async {
    _googleFont = font;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGoogleFont, font ?? '');
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, size);
  }

  Future<void> setLineHeight(double height) async {
    _lineHeight = height;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLineHeight, height);
  }

  Future<void> setBgColor(Color color) async {
    _bgColor = color;
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
