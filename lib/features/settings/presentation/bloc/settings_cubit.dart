import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/call_service.dart';
import '../../../../services/recording_service.dart';
import '../../../../theme/theme_provider.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._themeProvider, this._callService, this._recordingService) : super(SettingsState.initial());

  final ThemeProvider _themeProvider;
  final CallService _callService;
  final RecordingService _recordingService;

  void initialize() {
    _themeProvider.addListener(_onThemeChanged);
    _load();
  }

  Future<void> _load() async {
    final autoRecord = await _recordingService.autoRecordEnabled;
    final sims = await _callService.getSimInfo();
    emit(state.copyWith(autoRecord: autoRecord, sims: sims, themeMode: _themeProvider.themeMode, useDynamicColor: _themeProvider.useDynamicColor, seedColor: _themeProvider.seedColor, loaded: true));
  }

  Future<void> setAutoRecord(bool value) async {
    await _recordingService.setAutoRecord(value);
    emit(state.copyWith(autoRecord: value));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _themeProvider.setThemeMode(mode);
  }

  Future<void> setUseDynamicColor(bool value) async {
    await _themeProvider.setUseDynamicColor(value);
  }

  Future<void> setSeedColor(Color color) async {
    await _themeProvider.setSeedColor(color);
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

  void _onThemeChanged() {
    emit(state.copyWith(themeMode: _themeProvider.themeMode, useDynamicColor: _themeProvider.useDynamicColor, seedColor: _themeProvider.seedColor));
  }

  @override
  Future<void> close() {
    _themeProvider.removeListener(_onThemeChanged);
    return super.close();
  }
}
