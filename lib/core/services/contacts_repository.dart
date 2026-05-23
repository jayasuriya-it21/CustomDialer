import '../utils/string_utils.dart';
import 'contact_service.dart';
import '../models/contact_entity.dart';

class ContactsRepository {
  final ContactService _contactService;

  ContactsRepository(this._contactService);

  Future<List<ContactEntity>> getContacts({bool forceRefresh = false}) async {
    final rawContacts = forceRefresh
        ? await _contactService.refresh()
        : (_contactService.isLoaded
            ? _contactService.cachedContacts
            : await _contactService.refresh());

    return rawContacts.map((item) => ContactEntity(
      contactId: StringUtils.safeUtf16(item['contactId']?.toString() ?? ''),
      name: StringUtils.safeUtf16(item['name']?.toString() ?? ''),
      number: StringUtils.safeUtf16(item['number']?.toString() ?? ''),
    )).toList();
  }
}
