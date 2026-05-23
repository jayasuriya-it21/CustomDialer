import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
      final grouped = _groupLogs(visible);
      emit(state.copyWith(isLoading: false, allLogs: payload.logs, visibleLogs: visible, groupedLogs: grouped, favorites: payload.favorites, clearError: true, clearDeleted: true));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: 'Unable to load recents', clearDeleted: true));
    }
  }

  Future<void> _onFilterChanged(RecentsFilterChanged event, Emitter<RecentsState> emit) async {
    final visible = _applyFilter(state.allLogs, event.filter);
    final grouped = _groupLogs(visible);
    emit(state.copyWith(filter: event.filter, visibleLogs: visible, groupedLogs: grouped, clearDeleted: true));
  }

  Future<void> _onDeleteRequested(RecentsDeleteRequested event, Emitter<RecentsState> emit) async {
    final existingIndex = state.allLogs.indexOf(event.log);
    if (existingIndex < 0) {
      return;
    }

    final updated = List<CallLogEntity>.from(state.allLogs)..remove(event.log);
    final visible = _applyFilter(updated, state.filter);
    final grouped = _groupLogs(visible);

    emit(state.copyWith(allLogs: updated, visibleLogs: visible, groupedLogs: grouped, lastDeletedLog: event.log, lastDeletedIndex: existingIndex));

    await _deleteCallLogUseCase(event.log.id);
  }

  Future<void> _onRestoreRequested(RecentsRestoreRequested event, Emitter<RecentsState> emit) async {
    final updated = List<CallLogEntity>.from(state.allLogs);
    final index = event.index.clamp(0, updated.length);
    updated.insert(index, event.log);
    final visible = _applyFilter(updated, state.filter);
    final grouped = _groupLogs(visible);
    emit(state.copyWith(allLogs: updated, visibleLogs: visible, groupedLogs: grouped, clearDeleted: true));
  }

  static List<CallLogEntity> _applyFilter(List<CallLogEntity> logs, RecentsFilter filter) {
    if (filter == RecentsFilter.missed) {
      return logs.where((log) => log.isMissed).toList();
    }
    return List<CallLogEntity>.from(logs);
  }

  // Direct execution — grouping ~300 call logs is O(n) and takes <2ms.
  // compute() isolate spawn overhead (~15ms) makes it slower, not faster.
  static List<RecentItem> _groupLogs(List<CallLogEntity> logs) {
    final List<RecentItem> items = [];
    String? currentHeader;

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    for (final log in logs) {
      final date = DateTime.fromMillisecondsSinceEpoch(log.date);
      final comparisonDate = DateTime(date.year, date.month, date.day);

      String header;
      if (comparisonDate == todayDate) {
        header = 'Today';
      } else if (comparisonDate == yesterdayDate) {
        header = 'Yesterday';
      } else {
        header = DateFormat('MMMM yyyy').format(date);
      }

      if (currentHeader != header) {
        currentHeader = header;
        items.add(HeaderItem(header));
      }
      items.add(LogItem(log));
    }
    return items;
  }
}
