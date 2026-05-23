import '../utils/string_utils.dart';
import 'call_service.dart';
import 'favorites_service.dart';
import 'contacts_repository.dart';
import '../models/call_log_entity.dart';
import '../models/recents_payload.dart';

class RecentsRepository {
  final CallService _callService;
  final ContactsRepository _contactsRepository;
  final FavoritesService _favoritesService;

  RecentsRepository(this._callService, this._contactsRepository, this._favoritesService);

  Future<RecentsPayload> getRecents({bool forceRefresh = false}) async {
    final logs = await _callService.getCallLog();
    final mappedLogs = logs.map((item) => CallLogEntity(
      id: StringUtils.safeUtf16(item['id']?.toString() ?? '${item['date']}_${item['number']}_${item['type']}'),
      name: StringUtils.safeUtf16(item['name']?.toString() ?? ''),
      number: StringUtils.safeUtf16(item['number']?.toString() ?? ''),
      type: item['type'] as int? ?? 0,
      date: item['date'] as int? ?? 0,
      duration: item['duration'] as int? ?? 0,
    )).toList();

    await _favoritesService.load();
    final contacts = await _contactsRepository.getContacts(forceRefresh: forceRefresh);
    final favoriteContacts = contacts.where((contact) => _favoritesService.isFavorite(contact.contactId)).toList();

    return RecentsPayload(logs: mappedLogs, favorites: favoriteContacts);
  }

  Future<void> deleteCallLog(String id) {
    return _callService.deleteCallLog(id);
  }
}
