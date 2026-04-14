import '../../../contacts/domain/entities/contact_entity.dart';
import '../entities/sim_info_entity.dart';

abstract class DialerRepository {
  Future<List<ContactEntity>> getContacts();
  Future<List<SimInfoEntity>> getSimInfo();
  Future<bool> makeCall(String number);
  Future<void> addContact(String number);
  Future<void> openVideoCall(String number);
}
