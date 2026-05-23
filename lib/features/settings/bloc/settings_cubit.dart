import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/call_service.dart';
import '../../../../core/services/recording_service.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/theme_state.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._themeCubit, this._callService, this._recordingService) : super(SettingsState.initial());

  final ThemeCubit _themeCubit;
  final CallService _callService;
  final RecordingService _recordingService;
  StreamSubscription<ThemeState>? _themeSub;

  void initialize() {
    // Listen to ThemeCubit stream instead of ChangeNotifier.
    _themeSub = _themeCubit.stream.listen(_onThemeChanged);
    _load();
  }

  Future<void> _load() async {
    final autoRecord = await _recordingService.autoRecordEnabled;
    final sims = await _callService.getSimInfo();
    final ts = _themeCubit.state;
    emit(state.copyWith(
      autoRecord: autoRecord,
      sims: sims,
      themeMode: ts.themeMode,
      useDynamicColor: ts.useDynamicColor,
      seedColor: ts.seedColor,
      loaded: true,
    ));
  }

  Future<void> setAutoRecord(bool value) async {
    await _recordingService.setAutoRecord(value);
    emit(state.copyWith(autoRecord: value));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _themeCubit.setThemeMode(mode);
  }

  Future<void> setUseDynamicColor(bool value) async {
    await _themeCubit.setUseDynamicColor(value);
  }

  Future<void> setSeedColor(Color color) async {
    await _themeCubit.setSeedColor(color);
  }

  Future<void> openCallForwardingSettings() {
    return _callService.openCallForwardingSettings();
  }

  Future<void> openBlockedNumbers() {
    return _callService.openBlockedNumbers();
  }

  Future<void> requestDefaultDialer() {
    return _callService.requestDefaultDialer();
  }

  Future<void> openRingtonePicker() {
    return _callService.openRingtonePicker();
  }

  void _onThemeChanged(ThemeState ts) {
    emit(state.copyWith(
      themeMode: ts.themeMode,
      useDynamicColor: ts.useDynamicColor,
      seedColor: ts.seedColor,
    ));
  }

  @override
  Future<void> close() {
    _themeSub?.cancel();
    return super.close();
  }
}
