import '../core/constants/shared_prefs_keys.dart';
import '../core/storage/app_storage.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  static const _key = SharedPrefsKeys.favoriteContacts;
  Set<String> _favoriteIds = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final list = await AppStorage.instance.getValue<List<dynamic>>(_key, []);
    _favoriteIds = list.map((e) => e.toString()).toSet();
    _loaded = true;
  }

  bool isFavorite(String contactId) => _favoriteIds.contains(contactId);

  Future<void> toggleFavorite(String contactId) async {
    if (_favoriteIds.contains(contactId)) {
      _favoriteIds.remove(contactId);
    } else {
      _favoriteIds.add(contactId);
    }
    await AppStorage.instance.putValue(_key, _favoriteIds.toList());
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
