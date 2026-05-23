import 'call_service.dart';
import 'contact_service.dart';
import 'contacts_repository.dart';
import '../models/contact_entity.dart';
import '../models/sim_info_entity.dart';

class DialerRepository {
  final ContactsRepository _contactsRepository;
  final CallService _callService;
  final ContactService _contactService;

  DialerRepository(this._contactsRepository, this._callService, this._contactService);

  Future<void> addContact(String number) {
    return _contactService.addContact(number);
  }

  Future<List<ContactEntity>> getContacts() {
    return _contactsRepository.getContacts();
  }

  Future<List<SimInfoEntity>> getSimInfo() async {
    final raw = await _callService.getSimInfo();
    return raw.map((sim) => SimInfoEntity(
      slot: sim['slot'] as int? ?? 0,
      carrier: sim['carrier']?.toString() ?? 'SIM',
      number: sim['number']?.toString() ?? 'No number',
    )).toList();
  }

  Future<bool> makeCall(String number) {
    return _callService.makeCall(number);
  }

  Future<void> openVideoCall(String number) {
    return _contactService.openVideoCall(number);
  }
}
