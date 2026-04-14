import 'package:equatable/equatable.dart';

import '../../domain/entities/call_log_entity.dart';

enum RecentsFilter { all, missed }

abstract class RecentsEvent extends Equatable {
  const RecentsEvent();

  @override
  List<Object?> get props => [];
}

class RecentsRequested extends RecentsEvent {
  const RecentsRequested({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class RecentsFilterChanged extends RecentsEvent {
  const RecentsFilterChanged(this.filter);

  final RecentsFilter filter;

  @override
  List<Object?> get props => [filter];
}

class RecentsDeleteRequested extends RecentsEvent {
  const RecentsDeleteRequested(this.log);

  final CallLogEntity log;

  @override
  List<Object?> get props => [log];
}

class RecentsRestoreRequested extends RecentsEvent {
  const RecentsRestoreRequested({required this.log, required this.index});

  final CallLogEntity log;
  final int index;

  @override
  List<Object?> get props => [log, index];
}
