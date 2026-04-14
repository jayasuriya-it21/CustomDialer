import '../../../../services/favorites_service.dart';
import '../../../contacts/domain/entities/contact_entity.dart';
import '../../../contacts/domain/repositories/contacts_repository.dart';
import '../../domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._contactsRepository, this._favoritesService);

  final ContactsRepository _contactsRepository;
  final FavoritesService _favoritesService;

  @override
  Future<List<ContactEntity>> getFavorites({bool forceRefresh = false}) async {
    await _favoritesService.load();
    final contacts = await _contactsRepository.getContacts(forceRefresh: forceRefresh);

    return contacts.where((contact) => _favoritesService.isFavorite(contact.contactId)).toList();
  }
}
