import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  const SettingsState({required this.autoRecord, required this.sims, required this.themeMode, required this.useDynamicColor, required this.seedColor, required this.loaded});

  final bool autoRecord;
  final List<Map<String, dynamic>> sims;
  final ThemeMode themeMode;
  final bool useDynamicColor;
  final Color seedColor;
  final bool loaded;

  factory SettingsState.initial() => const SettingsState(autoRecord: false, sims: <Map<String, dynamic>>[], themeMode: ThemeMode.system, useDynamicColor: true, seedColor: Color(0xFF1A73E8), loaded: false);

  SettingsState copyWith({bool? autoRecord, List<Map<String, dynamic>>? sims, ThemeMode? themeMode, bool? useDynamicColor, Color? seedColor, bool? loaded}) {
    return SettingsState(autoRecord: autoRecord ?? this.autoRecord, sims: sims ?? this.sims, themeMode: themeMode ?? this.themeMode, useDynamicColor: useDynamicColor ?? this.useDynamicColor, seedColor: seedColor ?? this.seedColor, loaded: loaded ?? this.loaded);
  }

  @override
  List<Object?> get props => [autoRecord, sims, themeMode, useDynamicColor, seedColor, loaded];
}
