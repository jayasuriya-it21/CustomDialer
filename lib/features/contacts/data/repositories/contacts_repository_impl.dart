import '../../../../services/contact_service.dart';
import '../../domain/entities/contact_entity.dart';
import '../../domain/repositories/contacts_repository.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  ContactsRepositoryImpl(this._contactService);

  final ContactService _contactService;

  @override
  Future<List<ContactEntity>> getContacts({bool forceRefresh = false}) async {
    final rawContacts = forceRefresh ? await _contactService.refresh() : (_contactService.isLoaded ? _contactService.cachedContacts : await _contactService.getContacts());

    return rawContacts.map((item) => ContactEntity(contactId: item['contactId']?.toString() ?? '', name: item['name']?.toString() ?? '', number: item['number']?.toString() ?? '')).toList();
  }
}
