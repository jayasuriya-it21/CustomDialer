import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ContactService {
  static const MethodChannel _channel = MethodChannel('com.example.google_dialer/incall');
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  List<Map<String, dynamic>> _cachedContacts = [];
  bool _contactsLoaded = false;

  bool get isLoaded => _contactsLoaded;
  List<Map<String, dynamic>> get cachedContacts => _cachedContacts;

  /// Pre-load contacts on app startup
  Future<void> preload() async {
    if (!_contactsLoaded) {
      _cachedContacts = await getContacts();
      _contactsLoaded = true;
    }
  }

  /// Force refresh contacts cache
  Future<List<Map<String, dynamic>>> refresh() async {
    _cachedContacts = await getContacts();
    _contactsLoaded = true;
    return _cachedContacts;
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    try {
      final result = await _channel.invokeMethod('getContacts');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint("Get contacts failed: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>> getContactDetails(String number) async {
    try {
      final result = await _channel.invokeMethod('getContactDetails', {'number': number});
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {}
    return {};
  }

  /// Lookup contact name from phone number (for incoming calls)
  Future<String> lookupName(String number) async {
    try {
      final details = await getContactDetails(number);
      final name = details['name'] as String?;
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    return number;
  }

  /// Open system "Add Contact" screen with pre-filled number
  Future<void> addContact(String number, {String? name}) async {
    try {
      await _channel.invokeMethod('addContact', {
        'number': number,
        'name': name ?? '',
      });
    } catch (e) {
      debugPrint("Add contact intent failed: $e");
    }
  }

  /// Open SMS app for a number
  Future<void> openSms(String number) async {
    try {
      await _channel.invokeMethod('openSms', {'number': number});
    } catch (e) {
      debugPrint("Open SMS failed: $e");
    }
  }

  /// Open WhatsApp chat (if installed)
  Future<bool> openWhatsApp(String number) async {
    try {
      final result = await _channel.invokeMethod('openWhatsApp', {'number': number});
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Open video call via available app
  Future<void> openVideoCall(String number) async {
    try {
      await _channel.invokeMethod('openVideoCall', {'number': number});
    } catch (e) {
      debugPrint("Video call failed: $e");
    }
  }
}
