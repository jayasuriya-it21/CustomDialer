import 'package:equatable/equatable.dart';

import '../../../contacts/domain/entities/contact_entity.dart';
import '../../domain/entities/call_log_entity.dart';
import 'recents_event.dart';

class RecentsState extends Equatable {
  const RecentsState({required this.isLoading, required this.allLogs, required this.visibleLogs, required this.favorites, required this.filter, this.error, this.lastDeletedLog, this.lastDeletedIndex});

  final bool isLoading;
  final List<CallLogEntity> allLogs;
  final List<CallLogEntity> visibleLogs;
  final List<ContactEntity> favorites;
  final RecentsFilter filter;
  final String? error;
  final CallLogEntity? lastDeletedLog;
  final int? lastDeletedIndex;

  factory RecentsState.initial() => const RecentsState(isLoading: true, allLogs: <CallLogEntity>[], visibleLogs: <CallLogEntity>[], favorites: <ContactEntity>[], filter: RecentsFilter.all);

  RecentsState copyWith({bool? isLoading, List<CallLogEntity>? allLogs, List<CallLogEntity>? visibleLogs, List<ContactEntity>? favorites, RecentsFilter? filter, String? error, bool clearError = false, CallLogEntity? lastDeletedLog, int? lastDeletedIndex, bool clearDeleted = false}) {
    return RecentsState(isLoading: isLoading ?? this.isLoading, allLogs: allLogs ?? this.allLogs, visibleLogs: visibleLogs ?? this.visibleLogs, favorites: favorites ?? this.favorites, filter: filter ?? this.filter, error: clearError ? null : (error ?? this.error), lastDeletedLog: clearDeleted ? null : (lastDeletedLog ?? this.lastDeletedLog), lastDeletedIndex: clearDeleted ? null : (lastDeletedIndex ?? this.lastDeletedIndex));
  }

  @override
  List<Object?> get props => [isLoading, allLogs, visibleLogs, favorites, filter, error, lastDeletedLog, lastDeletedIndex];
}
