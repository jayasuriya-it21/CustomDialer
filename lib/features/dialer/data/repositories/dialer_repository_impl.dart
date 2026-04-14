import '../../../../services/call_service.dart';
import '../../../../services/contact_service.dart';
import '../../../contacts/domain/entities/contact_entity.dart';
import '../../../contacts/domain/repositories/contacts_repository.dart';
import '../../domain/entities/sim_info_entity.dart';
import '../../domain/repositories/dialer_repository.dart';

class DialerRepositoryImpl implements DialerRepository {
  DialerRepositoryImpl(this._contactsRepository, this._callService, this._contactService);

  final ContactsRepository _contactsRepository;
  final CallService _callService;
  final ContactService _contactService;

  @override
  Future<void> addContact(String number) {
    return _contactService.addContact(number);
  }

  @override
  Future<List<ContactEntity>> getContacts() {
    return _contactsRepository.getContacts();
  }

  @override
  Future<List<SimInfoEntity>> getSimInfo() async {
    final raw = await _callService.getSimInfo();
    return raw.map((sim) => SimInfoEntity(slot: sim['slot'] as int? ?? 0, carrier: sim['carrier']?.toString() ?? 'SIM', number: sim['number']?.toString() ?? 'No number')).toList();
  }

  @override
  Future<bool> makeCall(String number) {
    return _callService.makeCall(number);
  }

  @override
  Future<void> openVideoCall(String number) {
    return _contactService.openVideoCall(number);
  }
}
