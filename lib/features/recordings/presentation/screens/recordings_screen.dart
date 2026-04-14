import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/service_locator.dart';
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
            appBar: AppBar(title: const Text('Recordings'), backgroundColor: cs.surface, surfaceTintColor: Colors.transparent),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : state.recordings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic_off_rounded, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.25)),
                        const SizedBox(height: 16),
                        Text('No recordings', style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Text('Call recordings will appear here', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _recordingsCubit.loadRecordings,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
    final displayName = meta.contactName.isNotEmpty ? meta.contactName : (meta.number.isNotEmpty ? meta.number : 'Unknown');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: isCurrentlyPlaying ? cs.primaryContainer.withValues(alpha: 0.3) : cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isCurrentlyPlaying && state.isPlaying ? cs.primary : cs.primaryContainer,
          child: Icon(isCurrentlyPlaying && state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: isCurrentlyPlaying && state.isPlaying ? cs.onPrimary : cs.onPrimaryContainer, size: 22),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(_formatDate(meta.dateMs), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            if (meta.durationSeconds > 0) ...[
              Text(' · ', style: TextStyle(color: cs.onSurfaceVariant)),
              Text(
                _formatDuration(meta.durationSeconds),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.share_rounded, size: 20, color: cs.primary),
              visualDensity: VisualDensity.compact,
              onPressed: () => _recordingsCubit.shareRecording(index),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 20, color: cs.error),
              visualDensity: VisualDensity.compact,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          ],
        ),
        onTap: () => _recordingsCubit.togglePlay(index),
      ),
    );
  }
}
