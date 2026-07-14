import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'tokens/app_colors.dart';
import 'tokens/app_type.dart';

/// Persistent theme + typography preferences for the reader.
class ThemeProvider extends ChangeNotifier {
  static const _keyThemeMode = 'theme_mode';
  static const _keySepiaMode = 'sepia_mode';
  static const _keyFontFamily = 'font_family';
  static const _keyGoogleFont = 'google_font';
  static const _keyFontSize = 'font_size';
  static const _keyLineHeight = 'line_height';
  static const _keyAccentIndex = 'accent_index';
  static const _keyReadingFont = 'reading_font';
  static const _keyPageWidth = 'page_width';
  static const _keyTextAlign = 'text_align';
  static const _keyHyphenation = 'hyphenation';
  static const _keyReducedMotion = 'reduced_motion';
  static const _keyDefaultHighlight = 'default_highlight';
  static const _keyHandMode = 'hand_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _sepiaMode = false;
  String _fontFamily = AppType.uiFont;
  String? _googleFont;
  double _fontSize = 17.0;
  double _lineHeight = 1.65;
  AccentPreset _accent = AccentPreset.indigo;
  ReadingFont _readingFont = ReadingFont.literata;
  double _pageWidth = 680;
  TextAlign _textAlign = TextAlign.left;
  bool _hyphenation = true;
  bool _reducedMotion = false;
  String _defaultHighlight = 'yellow';
  HandMode _handMode = HandMode.right;

  ThemeMode get themeMode => _themeMode;
  bool get sepiaMode => _sepiaMode;
  String get fontFamily => _fontFamily;
  String? get googleFont => _googleFont;
  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  AccentPreset get accent => _accent;
  ReadingFont get readingFont => _readingFont;
  double get pageWidth => _pageWidth;
  TextAlign get textAlign => _textAlign;
  bool get hyphenation => _hyphenation;
  bool get reducedMotion => _reducedMotion;
  String get defaultHighlight => _defaultHighlight;
  HandMode get handMode => _handMode;

  Color get accentColor {
    if (_sepiaMode) return AppColors.sepiaAccent;
    final isDark = isDarkMode;
    switch (_accent) {
      case AccentPreset.indigo:
        return isDark ? AppColors.accentIndigoDark : AppColors.accentIndigo;
      case AccentPreset.amber:
        return isDark ? AppColors.accentAmberDark : AppColors.accentAmber;
      case AccentPreset.forest:
        return isDark ? AppColors.accentForestDark : AppColors.accentForest;
    }
  }

  /// The current page background color, matching the active theme/sepia state.
  Color get bgColor {
    if (_sepiaMode) return AppColors.sepiaBg;
    return isDarkMode ? AppColors.darkBg : AppColors.lightBg;
  }

  /// Returns the resolved Google Fonts family for the reader body, or null
  /// to use the system serif.
  String? get readingFontFamily {
    switch (_readingFont) {
      case ReadingFont.system:
        return null;
      case ReadingFont.literata:
        return AppType.readingFont;
      case ReadingFont.inter:
        return AppType.uiFont;
    }
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  bool get isDark => isDarkMode;
  bool get isSepia => _sepiaMode;

  ThemeData get lightTheme => AppTheme.lightTheme();
  ThemeData get darkTheme => AppTheme.darkTheme();
  ThemeData get sepiaTheme => AppTheme.sepiaTheme();

  ThemeData get currentTheme {
    if (_sepiaMode) return sepiaTheme;
    return isDark ? darkTheme : lightTheme;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt(_keyThemeMode) ?? 0];
    _sepiaMode = prefs.getBool(_keySepiaMode) ?? false;
    _fontFamily = prefs.getString(_keyFontFamily) ?? AppType.uiFont;
    final fontStr = prefs.getString(_keyGoogleFont);
    _googleFont = fontStr?.isNotEmpty == true ? fontStr : null;
    _fontSize = prefs.getDouble(_keyFontSize) ?? 17.0;
    _lineHeight = prefs.getDouble(_keyLineHeight) ?? 1.65;
    _accent = AccentPreset.values[prefs.getInt(_keyAccentIndex) ?? 0];
    _readingFont =
        ReadingFont.values[prefs.getInt(_keyReadingFont) ?? 1];
    _pageWidth = prefs.getDouble(_keyPageWidth) ?? 680;
    _textAlign = TextAlign.values[prefs.getInt(_keyTextAlign) ?? 0];
    _hyphenation = prefs.getBool(_keyHyphenation) ?? true;
    _reducedMotion = prefs.getBool(_keyReducedMotion) ?? false;
    _defaultHighlight = prefs.getString(_keyDefaultHighlight) ?? 'yellow';
    _handMode = HandMode.values[prefs.getInt(_keyHandMode) ?? 1];
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _sepiaMode = false;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
    await prefs.setBool(_keySepiaMode, false);
  }

  Future<void> setSepiaMode(bool value) async {
    _sepiaMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySepiaMode, value);
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

  Future<void> setAccent(AccentPreset accent) async {
    _accent = accent;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccentIndex, accent.index);
  }

  Future<void> setReadingFont(ReadingFont font) async {
    _readingFont = font;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReadingFont, font.index);
  }

  Future<void> setPageWidth(double width) async {
    _pageWidth = width;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPageWidth, width);
  }

  Future<void> setTextAlign(TextAlign align) async {
    _textAlign = align;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTextAlign, align.index);
  }

  Future<void> setHyphenation(bool value) async {
    _hyphenation = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHyphenation, value);
  }

  Future<void> setReducedMotion(bool value) async {
    _reducedMotion = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReducedMotion, value);
  }

  Future<void> setDefaultHighlight(String key) async {
    _defaultHighlight = key;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultHighlight, key);
  }

  Future<void> setHandMode(HandMode mode) async {
    _handMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHandMode, mode.index);
  }

  void toggleTheme() {
    setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}

enum HandMode { left, right }

enum AccentPreset { indigo, amber, forest }

enum ReadingFont { system, literata, inter }
