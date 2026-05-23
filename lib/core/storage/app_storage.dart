import 'package:hive_flutter/hive_flutter.dart';

class AppStorage {
  AppStorage._();

  static const String _boxName = 'google_dialer_box';
  static final AppStorage instance = AppStorage._();

  Box<dynamic>? _box;
  Future<void>? _openFuture;
  static bool _hiveInitialized = false;

  /// Call once in main() before anything else touches storage.
  static Future<void> init() async {
    if (_hiveInitialized) return;
    await Hive.initFlutter();
    _hiveInitialized = true;
  }

  Future<void> ensureReady() {
    if (_box != null && _box!.isOpen) {
      return Future.value();
    }
    _openFuture ??= _openBox();
    return _openFuture!;
  }

  Future<void> _openBox() async {
    if (!_hiveInitialized) await init();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  Future<T> getValue<T>(String key, T defaultValue) async {
    await ensureReady();
    final value = _box!.get(key);
    if (value is T) {
      return value;
    }
    return defaultValue;
  }

  Future<void> putValue(String key, dynamic value) async {
    await ensureReady();
    await _box!.put(key, value);
  }
}
