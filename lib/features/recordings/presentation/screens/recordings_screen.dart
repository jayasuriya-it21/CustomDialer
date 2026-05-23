import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../widgets/contact_avatar.dart';
import '../bloc/recordings_cubit.dart';
import '../bloc/recordings_state.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  late final RecordingsCubit _recordingsCubit;

  @override
  void initState() {
    super.initState();
    _recordingsCubit = getIt<RecordingsCubit>();
    _recordingsCubit.initialize();
  }

  @override
  void dispose() {
    _recordingsCubit.close();
    super.dispose();
  }

  String _formatDate(int ms) {
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat('MMM d, yyyy · h:mm a').format(date);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _recordingsCubit,
      child: BlocBuilder<RecordingsCubit, RecordingsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: cs.surface,
            appBar: AppBar(
              title: const Text(
                'Recordings',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
              ),
              backgroundColor: cs.surface,
              elevation: 0,
              scrolledUnderElevation: 2,
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : state.recordings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.mic_off_rounded,
                                size: 48,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No recordings yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your call recordings will appear here',
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _recordingsCubit.loadRecordings,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: state.recordings.length,
                          itemBuilder: (_, i) => _buildRecordingItem(context, state, i),
                        ),
                      ),
          );
        },
      ),
    );
  }

  Widget _buildRecordingItem(BuildContext context, RecordingsState state, int index) {
    final meta = state.recordings[index];
    final cs = Theme.of(context).colorScheme;
    final isCurrentlyPlaying = state.playingIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = meta.contactName.isNotEmpty
        ? meta.contactName
        : (meta.number.isNotEmpty ? meta.number : 'Unknown');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: isCurrentlyPlaying
          ? cs.primaryContainer.withValues(alpha: isDark ? 0.25 : 0.35)
          : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCurrentlyPlaying
              ? cs.primary.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Stack(
              alignment: Alignment.center,
              children: [
                ContactAvatar(name: displayName, radius: 22),
                InkWell(
                  onTap: () => _recordingsCubit.togglePlay(index),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: isCurrentlyPlaying && state.isPlaying ? 0.4 : 0.15),
                    ),
                    child: Icon(
                      isCurrentlyPlaying && state.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(meta.dateMs),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  if (meta.durationSeconds > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(meta.durationSeconds),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.share_rounded, size: 16, color: cs.primary),
                  ),
                  onPressed: () => _recordingsCubit.shareRecording(index),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.error.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_outline_rounded, size: 16, color: cs.error),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _recordingsCubit.deleteRecording(index);
                    if (!mounted) {
                      return;
                    }
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text('Recording deleted'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (isCurrentlyPlaying) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: StreamBuilder<Duration>(
                stream: _recordingsCubit.audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = _recordingsCubit.audioPlayer.duration ??
                      Duration(seconds: meta.durationSeconds);

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position.inSeconds),
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            _formatDuration(duration.inSeconds),
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          activeTrackColor: cs.primary,
                          inactiveTrackColor: cs.outlineVariant.withValues(alpha: 0.4),
                          thumbColor: cs.primary,
                          activeTickMarkColor: Colors.transparent,
                          inactiveTickMarkColor: Colors.transparent,
                        ),
                        child: Slider(
                          value: position.inMilliseconds.toDouble().clamp(
                                0.0,
                                duration.inMilliseconds.toDouble(),
                              ),
                          min: 0.0,
                          max: duration.inMilliseconds.toDouble() > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (val) {
                            _recordingsCubit.audioPlayer.seek(
                              Duration(milliseconds: val.toInt()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Playback controls row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10_rounded, size: 24),
                            color: cs.onSurfaceVariant,
                            onPressed: () {
                              final newPos = position - const Duration(seconds: 10);
                              _recordingsCubit.audioPlayer.seek(
                                newPos < Duration.zero ? Duration.zero : newPos,
                              );
                            },
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: Icon(
                              state.isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_filled_rounded,
                              size: 48,
                              color: cs.primary,
                            ),
                            onPressed: () => _recordingsCubit.togglePlay(index),
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: const Icon(Icons.forward_10_rounded, size: 24),
                            color: cs.onSurfaceVariant,
                            onPressed: () {
                              final newPos = position + const Duration(seconds: 10);
                              _recordingsCubit.audioPlayer.seek(
                                newPos > duration ? duration : newPos,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ]
        ],
      ),
    );
  }
}
