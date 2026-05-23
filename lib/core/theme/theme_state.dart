import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  const ThemeState({
    required this.themeMode,
    required this.seedColor,
    required this.useDynamicColor,
  });

  final ThemeMode themeMode;
  final Color seedColor;
  final bool useDynamicColor;

  factory ThemeState.initial() => const ThemeState(
        themeMode: ThemeMode.system,
        seedColor: Color(0xFF1A73E8),
        useDynamicColor: true,
      );

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
    bool? useDynamicColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    );
  }

  @override
  List<Object?> get props => [themeMode, seedColor, useDynamicColor];
}
