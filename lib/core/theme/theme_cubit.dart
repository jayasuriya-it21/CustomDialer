import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/shared_prefs_keys.dart';
import '../storage/app_storage.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState.initial());

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

  /// Load persisted theme preferences. Call after AppStorage is ready.
  Future<void> loadPreferences() async {
    final modeIndex = await AppStorage.instance
        .getValue<int>(SharedPrefsKeys.themeMode, 0);
    final colorValue = await AppStorage.instance
        .getValue<int>(SharedPrefsKeys.seedColor, 0xFF1A73E8);
    final useDynamic = await AppStorage.instance
        .getValue<bool>(SharedPrefsKeys.useDynamicColor, true);

    emit(state.copyWith(
      themeMode: ThemeMode.values[modeIndex.clamp(0, 2)],
      seedColor: Color(colorValue),
      useDynamicColor: useDynamic,
    ));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await AppStorage.instance
        .putValue(SharedPrefsKeys.themeMode, mode.index);
  }

  Future<void> setSeedColor(Color color) async {
    emit(state.copyWith(seedColor: color));
    await AppStorage.instance
        .putValue(SharedPrefsKeys.seedColor, color.toARGB32());
  }

  Future<void> setUseDynamicColor(bool value) async {
    emit(state.copyWith(useDynamicColor: value));
    await AppStorage.instance
        .putValue(SharedPrefsKeys.useDynamicColor, value);
  }
}
