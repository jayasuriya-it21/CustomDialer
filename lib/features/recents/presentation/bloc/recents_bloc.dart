import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/call_log_entity.dart';
import '../../domain/usecases/delete_call_log_usecase.dart';
import '../../domain/usecases/get_recents_usecase.dart';
import 'recents_event.dart';
import 'recents_state.dart';

class RecentsBloc extends Bloc<RecentsEvent, RecentsState> {
  RecentsBloc(this._getRecentsUseCase, this._deleteCallLogUseCase) : super(RecentsState.initial()) {
    on<RecentsRequested>(_onRequested);
    on<RecentsFilterChanged>(_onFilterChanged);
    on<RecentsDeleteRequested>(_onDeleteRequested);
    on<RecentsRestoreRequested>(_onRestoreRequested);
  }

  final GetRecentsUseCase _getRecentsUseCase;
  final DeleteCallLogUseCase _deleteCallLogUseCase;

  Future<void> _onRequested(RecentsRequested event, Emitter<RecentsState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearDeleted: true));
    try {
      final payload = await _getRecentsUseCase(forceRefresh: event.forceRefresh);
      final visible = _applyFilter(payload.logs, state.filter);
      emit(state.copyWith(isLoading: false, allLogs: payload.logs, visibleLogs: visible, favorites: payload.favorites, clearError: true, clearDeleted: true));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: 'Unable to load recents', clearDeleted: true));
    }
  }

  void _onFilterChanged(RecentsFilterChanged event, Emitter<RecentsState> emit) {
    emit(state.copyWith(filter: event.filter, visibleLogs: _applyFilter(state.allLogs, event.filter), clearDeleted: true));
  }

  Future<void> _onDeleteRequested(RecentsDeleteRequested event, Emitter<RecentsState> emit) async {
    final existingIndex = state.allLogs.indexOf(event.log);
    if (existingIndex < 0) {
      return;
    }

    final updated = List<CallLogEntity>.from(state.allLogs)..remove(event.log);

    emit(state.copyWith(allLogs: updated, visibleLogs: _applyFilter(updated, state.filter), lastDeletedLog: event.log, lastDeletedIndex: existingIndex));

    await _deleteCallLogUseCase(event.log.id);
  }

  void _onRestoreRequested(RecentsRestoreRequested event, Emitter<RecentsState> emit) {
    final updated = List<CallLogEntity>.from(state.allLogs);
    final index = event.index.clamp(0, updated.length);
    updated.insert(index, event.log);
    emit(state.copyWith(allLogs: updated, visibleLogs: _applyFilter(updated, state.filter), clearDeleted: true));
  }

  List<CallLogEntity> _applyFilter(List<CallLogEntity> logs, RecentsFilter filter) {
    if (filter == RecentsFilter.missed) {
      return logs.where((log) => log.isMissed).toList();
    }
    return List<CallLogEntity>.from(logs);
  }
}
