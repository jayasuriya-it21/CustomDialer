import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';

class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider _instance = ThemeProvider._internal();
  factory ThemeProvider() => _instance;
  ThemeProvider._internal() {
    _loadPrefs();
  }

  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = const Color(0xFF1A73E8);
  bool _useDynamicColor = true;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get useDynamicColor => _useDynamicColor;

  static const List<Color> presetColors = [
    Color(0xFF1A73E8), // Google Blue
    Color(0xFF34A853), // Google Green
    Color(0xFFEA4335), // Google Red
    Color(0xFFFBBC04), // Google Yellow
    Color(0xFF8430CE), // Purple
    Color(0xFF00897B), // Teal
    Color(0xFFE91E63), // Pink
    Color(0xFFFF6D00), // Orange
    Color(0xFF455A64), // Blue Grey
    Color(0xFF1DE9B6), // Mint
  ];

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('themeMode') ?? 0;
    final colorValue = prefs.getInt('seedColor') ?? 0xFF1A73E8;
    _useDynamicColor = prefs.getBool('useDynamicColor') ?? true;

    _themeMode = ThemeMode.values[modeIndex.clamp(0, 2)];
    _seedColor = Color(colorValue);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seedColor', color.value);
  }

  Future<void> setUseDynamicColor(bool value) async {
    _useDynamicColor = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDynamicColor', value);
  }

  ThemeData buildLightTheme({ColorScheme? dynamicScheme}) {
    ColorScheme scheme;
    if (_useDynamicColor && dynamicScheme != null) {
      scheme = dynamicScheme.harmonized();
    } else {
      scheme = ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      );
    }
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withOpacity(0.3)),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  ThemeData buildDarkTheme({ColorScheme? dynamicScheme}) {
    ColorScheme scheme;
    if (_useDynamicColor && dynamicScheme != null) {
      scheme = dynamicScheme.harmonized();
    } else {
      scheme = ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      );
    }
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withOpacity(0.3)),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
