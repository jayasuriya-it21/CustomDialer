import 'package:equatable/equatable.dart';

import '../../../core/models/contact_entity.dart';
import '../../../core/models/call_log_entity.dart';
import 'recents_event.dart';

abstract class RecentItem {}

class HeaderItem extends RecentItem {
  final String title;
  HeaderItem(this.title);
}

class LogItem extends RecentItem {
  final CallLogEntity log;
  LogItem(this.log);
}

class RecentsState extends Equatable {
  const RecentsState({required this.isLoading, required this.allLogs, required this.visibleLogs, this.groupedLogs = const [], required this.favorites, required this.filter, this.error, this.lastDeletedLog, this.lastDeletedIndex});

  final bool isLoading;
  final List<CallLogEntity> allLogs;
  final List<CallLogEntity> visibleLogs;
  final List<RecentItem> groupedLogs;
  final List<ContactEntity> favorites;
  final RecentsFilter filter;
  final String? error;
  final CallLogEntity? lastDeletedLog;
  final int? lastDeletedIndex;

  factory RecentsState.initial() => const RecentsState(isLoading: true, allLogs: <CallLogEntity>[], visibleLogs: <CallLogEntity>[], groupedLogs: <RecentItem>[], favorites: <ContactEntity>[], filter: RecentsFilter.all);

  RecentsState copyWith({bool? isLoading, List<CallLogEntity>? allLogs, List<CallLogEntity>? visibleLogs, List<RecentItem>? groupedLogs, List<ContactEntity>? favorites, RecentsFilter? filter, String? error, bool clearError = false, CallLogEntity? lastDeletedLog, int? lastDeletedIndex, bool clearDeleted = false}) {
    return RecentsState(isLoading: isLoading ?? this.isLoading, allLogs: allLogs ?? this.allLogs, visibleLogs: visibleLogs ?? this.visibleLogs, groupedLogs: groupedLogs ?? this.groupedLogs, favorites: favorites ?? this.favorites, filter: filter ?? this.filter, error: clearError ? null : (error ?? this.error), lastDeletedLog: clearDeleted ? null : (lastDeletedLog ?? this.lastDeletedLog), lastDeletedIndex: clearDeleted ? null : (lastDeletedIndex ?? this.lastDeletedIndex));
  }

  @override
  List<Object?> get props => [isLoading, allLogs, visibleLogs, groupedLogs, favorites, filter, error, lastDeletedLog, lastDeletedIndex];
}
