import 'package:equatable/equatable.dart';

import '../../../../services/recording_service.dart';

class RecordingsState extends Equatable {
  const RecordingsState({required this.isLoading, required this.recordings, required this.playingIndex, required this.isPlaying});

  final bool isLoading;
  final List<RecordingMeta> recordings;
  final int? playingIndex;
  final bool isPlaying;

  factory RecordingsState.initial() => const RecordingsState(isLoading: true, recordings: <RecordingMeta>[], playingIndex: null, isPlaying: false);

  RecordingsState copyWith({bool? isLoading, List<RecordingMeta>? recordings, int? playingIndex, bool clearPlayingIndex = false, bool? isPlaying}) {
    return RecordingsState(isLoading: isLoading ?? this.isLoading, recordings: recordings ?? this.recordings, playingIndex: clearPlayingIndex ? null : (playingIndex ?? this.playingIndex), isPlaying: isPlaying ?? this.isPlaying);
  }

  @override
  List<Object?> get props => [isLoading, recordings, playingIndex, isPlaying];
}
