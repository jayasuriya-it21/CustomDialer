import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../services/recording_service.dart';
import 'recordings_state.dart';

class RecordingsCubit extends Cubit<RecordingsState> {
  RecordingsCubit(this._recordingService) : super(RecordingsState.initial()) {
    _playerSub = _audioPlayer.playerStateStream.listen(_onPlayerStateChanged);
  }

  final RecordingService _recordingService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;

  Future<void> initialize() async {
    await loadRecordings();
  }

  Future<void> loadRecordings() async {
    emit(state.copyWith(isLoading: true));
    final recordings = await _recordingService.getRecordings();
    emit(state.copyWith(isLoading: false, recordings: recordings));
  }

  Future<void> togglePlay(int index) async {
    if (state.playingIndex == index && state.isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    if (state.playingIndex != index) {
      await _audioPlayer.setFilePath(state.recordings[index].path);
    }
    emit(state.copyWith(playingIndex: index));
    await _audioPlayer.play();
  }

  Future<void> deleteRecording(int index) async {
    final meta = state.recordings[index];
    if (state.playingIndex == index) {
      await _audioPlayer.stop();
    }

    await _recordingService.deleteRecording(meta.path);
    final updated = List<RecordingMeta>.from(state.recordings)..removeAt(index);
    emit(state.copyWith(recordings: updated, clearPlayingIndex: state.playingIndex == index, isPlaying: false));
  }

  Future<void> shareRecording(int index) async {
    final meta = state.recordings[index];
    await Share.shareXFiles([XFile(meta.path)], text: 'Call recording: ${meta.contactName}');
  }

  void _onPlayerStateChanged(PlayerState playerState) {
    if (playerState.processingState == ProcessingState.completed) {
      emit(state.copyWith(clearPlayingIndex: true, isPlaying: false));
      return;
    }
    emit(state.copyWith(isPlaying: playerState.playing));
  }

  @override
  Future<void> close() async {
    await _playerSub?.cancel();
    await _audioPlayer.dispose();
    return super.close();
  }
}
