import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../core/constants/shared_prefs_keys.dart';
import '../core/storage/app_storage.dart';

class RecordingMeta {
  final String path;
  final String contactName;
  final String number;
  final int dateMs;
  final int durationSeconds;

  RecordingMeta({required this.path, required this.contactName, required this.number, required this.dateMs, this.durationSeconds = 0});

  Map<String, dynamic> toJson() => {'path': path, 'contactName': contactName, 'number': number, 'dateMs': dateMs, 'durationSeconds': durationSeconds};

  factory RecordingMeta.fromJson(Map<String, dynamic> json) => RecordingMeta(path: json['path'] as String? ?? '', contactName: json['contactName'] as String? ?? '', number: json['number'] as String? ?? '', dateMs: json['dateMs'] as int? ?? 0, durationSeconds: json['durationSeconds'] as int? ?? 0);
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

  static const _metaKey = SharedPrefsKeys.callRecordingsMeta;
  static const _autoRecordKey = SharedPrefsKeys.autoRecordCalls;

  Future<bool> get autoRecordEnabled async {
    return AppStorage.instance.getValue<bool>(_autoRecordKey, false);
  }

  Future<void> setAutoRecord(bool value) async {
    await AppStorage.instance.putValue(_autoRecordKey, value);
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

      await _recorder!.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000), path: _currentPath!);

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
        final duration = _recordStartTime != null ? DateTime.now().difference(_recordStartTime!).inSeconds : 0;

        final meta = RecordingMeta(path: _currentPath!, contactName: _currentContactName, number: _currentNumber, dateMs: DateTime.now().millisecondsSinceEpoch, durationSeconds: duration);
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
    final existing = await AppStorage.instance.getValue<List<dynamic>>(_metaKey, []);
    final entries = existing.map((e) => e.toString()).toList();
    entries.add(jsonEncode(meta.toJson()));
    await AppStorage.instance.putValue(_metaKey, entries);
  }

  Future<List<RecordingMeta>> getRecordings() async {
    final list = await AppStorage.instance.getValue<List<dynamic>>(_metaKey, []);
    final rawList = list.map((e) => e.toString()).toList();
    final recordings = <RecordingMeta>[];

    for (final raw in rawList) {
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

      final list = await AppStorage.instance.getValue<List<dynamic>>(_metaKey, []);
      final filtered = list.map((e) => e.toString()).toList();
      filtered.removeWhere((raw) {
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          return json['path'] == path;
        } catch (_) {
          return false;
        }
      });
      await AppStorage.instance.putValue(_metaKey, filtered);
    } catch (e) {
      debugPrint("Delete recording error: $e");
    }
  }

  void dispose() {
    _recorder?.dispose();
    _recorder = null;
  }
}
