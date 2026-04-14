import '../../../contacts/domain/entities/contact_entity.dart';
import '../entities/sim_info_entity.dart';
import '../repositories/dialer_repository.dart';

class DialerData {
  const DialerData({required this.contacts, required this.sims});

  final List<ContactEntity> contacts;
  final List<SimInfoEntity> sims;
}

class LoadDialerDataUseCase {
  LoadDialerDataUseCase(this._repository);

  final DialerRepository _repository;

  Future<DialerData> call() async {
    final contacts = await _repository.getContacts();
    final sims = await _repository.getSimInfo();
    return DialerData(contacts: contacts, sims: sims);
  }
}
