import '../../../../services/call_service.dart';
import '../../../../services/favorites_service.dart';
import '../../../contacts/domain/repositories/contacts_repository.dart';
import '../../domain/entities/call_log_entity.dart';
import '../../domain/entities/recents_payload.dart';
import '../../domain/repositories/recents_repository.dart';

class RecentsRepositoryImpl implements RecentsRepository {
  RecentsRepositoryImpl(this._callService, this._contactsRepository, this._favoritesService);

  final CallService _callService;
  final ContactsRepository _contactsRepository;
  final FavoritesService _favoritesService;

  @override
  Future<RecentsPayload> getRecents({bool forceRefresh = false}) async {
    final logs = await _callService.getCallLog();
    final mappedLogs = logs.map((item) => CallLogEntity(id: item['id']?.toString() ?? '${item['date']}_${item['number']}_${item['type']}', name: item['name']?.toString() ?? '', number: item['number']?.toString() ?? '', type: item['type'] as int? ?? 0, date: item['date'] as int? ?? 0, duration: item['duration'] as int? ?? 0)).toList();

    await _favoritesService.load();
    final contacts = await _contactsRepository.getContacts(forceRefresh: forceRefresh);
    final favoriteContacts = contacts.where((contact) => _favoritesService.isFavorite(contact.contactId)).toList();

    return RecentsPayload(logs: mappedLogs, favorites: favoriteContacts);
  }

  @override
  Future<void> deleteCallLog(String id) {
    return _callService.deleteCallLog(id);
  }
}
