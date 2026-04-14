import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  static const _key = 'favorite_contacts';
  Set<String> _favoriteIds = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    _favoriteIds = list.toSet();
    _loaded = true;
  }

  bool isFavorite(String contactId) => _favoriteIds.contains(contactId);

  Future<void> toggleFavorite(String contactId) async {
    if (_favoriteIds.contains(contactId)) {
      _favoriteIds.remove(contactId);
    } else {
      _favoriteIds.add(contactId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _favoriteIds.toList());
  }

  Set<String> get favoriteIds => _favoriteIds;

  /// Filter a contacts list to only favorites
  List<Map<String, dynamic>> filterFavorites(List<Map<String, dynamic>> contacts) {
    return contacts.where((c) {
      final id = c['contactId']?.toString() ?? '';
      return _favoriteIds.contains(id);
    }).toList();
  }
}
