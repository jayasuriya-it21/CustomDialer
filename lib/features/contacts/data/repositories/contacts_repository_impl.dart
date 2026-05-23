import '../../../../core/utils/string_utils.dart';
import '../../../../core/services/contact_service.dart';
import '../../domain/entities/contact_entity.dart';
import '../../domain/repositories/contacts_repository.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  ContactsRepositoryImpl(this._contactService);

  final ContactService _contactService;

  @override
  Future<List<ContactEntity>> getContacts({bool forceRefresh = false}) async {
    final rawContacts = forceRefresh
        ? await _contactService.refresh()
        : (_contactService.isLoaded
            ? _contactService.cachedContacts
            : await _contactService.refresh());

    return rawContacts.map((item) => ContactEntity(
      contactId: StringUtils.safeUtf16(item['contactId']?.toString()),
      name: StringUtils.safeUtf16(item['name']?.toString()),
      number: StringUtils.safeUtf16(item['number']?.toString()),
    )).toList();
  }
}
