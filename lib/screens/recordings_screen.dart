import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../services/recording_service.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  final RecordingService _recordingService = RecordingService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<RecordingMeta> _recordings = [];
  bool _isLoading = true;
  int? _playingIndex;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _playingIndex = null;
            _isPlaying = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    final recordings = await _recordingService.getRecordings();
    if (mounted) {
      setState(() {
        _recordings = recordings;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePlay(int index) async {
    if (_playingIndex == index && _isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_playingIndex != index) {
        await _audioPlayer.setFilePath(_recordings[index].path);
      }
      _playingIndex = index;
      await _audioPlayer.play();
    }
  }

  Future<void> _deleteRecording(int index) async {
    final meta = _recordings[index];
    if (_playingIndex == index) {
      await _audioPlayer.stop();
      _playingIndex = null;
    }
    await _recordingService.deleteRecording(meta.path);
    _recordings.removeAt(index);

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Recording deleted'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _shareRecording(int index) async {
    final meta = _recordings[index];
    await Share.shareXFiles([XFile(meta.path)], text: 'Call recording: ${meta.contactName}');
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

    return Scaffold(
      appBar: AppBar(title: const Text('Recordings'), backgroundColor: cs.surface, surfaceTintColor: Colors.transparent),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _recordings.isEmpty
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
              onRefresh: _loadRecordings,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: _recordings.length,
                itemBuilder: (_, i) => _buildRecordingItem(i),
              ),
            ),
    );
  }

  Widget _buildRecordingItem(int index) {
    final meta = _recordings[index];
    final cs = Theme.of(context).colorScheme;
    final isCurrentlyPlaying = _playingIndex == index;
    final displayName = meta.contactName.isNotEmpty ? meta.contactName : (meta.number.isNotEmpty ? meta.number : 'Unknown');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: isCurrentlyPlaying ? cs.primaryContainer.withValues(alpha: 0.3) : cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isCurrentlyPlaying && _isPlaying ? cs.primary : cs.primaryContainer,
          child: Icon(isCurrentlyPlaying && _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: isCurrentlyPlaying && _isPlaying ? cs.onPrimary : cs.onPrimaryContainer, size: 22),
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
              onPressed: () => _shareRecording(index),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 20, color: cs.error),
              visualDensity: VisualDensity.compact,
              onPressed: () => _deleteRecording(index),
            ),
          ],
        ),
        onTap: () => _togglePlay(index),
      ),
    );
  }
}
