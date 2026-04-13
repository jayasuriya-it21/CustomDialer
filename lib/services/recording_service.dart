import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingMeta {
  final String path;
  final String contactName;
  final String number;
  final int dateMs;
  final int durationSeconds;

  RecordingMeta({
    required this.path,
    required this.contactName,
    required this.number,
    required this.dateMs,
    this.durationSeconds = 0,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'contactName': contactName,
    'number': number,
    'dateMs': dateMs,
    'durationSeconds': durationSeconds,
  };

  factory RecordingMeta.fromJson(Map<String, dynamic> json) => RecordingMeta(
    path: json['path'] as String? ?? '',
    contactName: json['contactName'] as String? ?? '',
    number: json['number'] as String? ?? '',
    dateMs: json['dateMs'] as int? ?? 0,
    durationSeconds: json['durationSeconds'] as int? ?? 0,
  );
}

class RecordingService {
  static final RecordingService _instance = RecordingService._internal();
  factory RecordingService() => _instance;
  RecordingService._internal();

  AudioRecorder? _recorder;
  bool _isRecording = false;
  String? _currentPath;
  DateTime? _recordStartTime;
  String _currentContactName = '';
  String _currentNumber = '';

  bool get isRecording => _isRecording;

  static const _metaKey = 'call_recordings_meta';
  static const _autoRecordKey = 'auto_record_calls';

  Future<bool> get autoRecordEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoRecordKey) ?? false;
  }

  Future<void> setAutoRecord(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoRecordKey, value);
  }

  Future<String> get _recordingsDir async {
    final dir = await getApplicationDocumentsDirectory();
    final recDir = Directory('${dir.path}/CallRecordings');
    if (!await recDir.exists()) {
      await recDir.create(recursive: true);
    }
    return recDir.path;
  }

  Future<String?> startRecording({String contactName = '', String number = ''}) async {
    try {
      _recorder ??= AudioRecorder();
      if (!await _recorder!.hasPermission()) return null;

      final dir = await _recordingsDir;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final safeName = contactName.replaceAll(RegExp(r'[^\w]'), '_');
      _currentPath = '$dir/call_${safeName}_$ts.m4a';
      _currentContactName = contactName;
      _currentNumber = number;

      await _recorder!.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: _currentPath!,
      );

      _isRecording = true;
      _recordStartTime = DateTime.now();
      return _currentPath;
    } catch (e) {
      debugPrint("RecordingService start error: $e");
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecording || _recorder == null) return null;
      final path = await _recorder!.stop();
      _isRecording = false;

      if (path != null && _currentPath != null) {
        final duration = _recordStartTime != null
            ? DateTime.now().difference(_recordStartTime!).inSeconds
            : 0;

        final meta = RecordingMeta(
          path: _currentPath!,
          contactName: _currentContactName,
          number: _currentNumber,
          dateMs: DateTime.now().millisecondsSinceEpoch,
          durationSeconds: duration,
        );
        await _saveMeta(meta);
      }

      _currentPath = null;
      _recordStartTime = null;
      return path;
    } catch (e) {
      debugPrint("RecordingService stop error: $e");
      _isRecording = false;
      return null;
    }
  }

  Future<void> _saveMeta(RecordingMeta meta) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_metaKey) ?? [];
    existing.add(jsonEncode(meta.toJson()));
    await prefs.setStringList(_metaKey, existing);
  }

  Future<List<RecordingMeta>> getRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_metaKey) ?? [];
    final recordings = <RecordingMeta>[];

    for (final raw in list) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final meta = RecordingMeta.fromJson(json);
        if (await File(meta.path).exists()) {
          recordings.add(meta);
        }
      } catch (_) {}
    }

    recordings.sort((a, b) => b.dateMs.compareTo(a.dateMs));
    return recordings;
  }

  Future<void> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();

      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_metaKey) ?? [];
      list.removeWhere((raw) {
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          return json['path'] == path;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(_metaKey, list);
    } catch (e) {
      debugPrint("Delete recording error: $e");
    }
  }

  void dispose() {
    _recorder?.dispose();
    _recorder = null;
  }
}
