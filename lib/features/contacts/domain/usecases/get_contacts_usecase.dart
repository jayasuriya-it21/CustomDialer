import '../entities/contact_entity.dart';
import '../repositories/contacts_repository.dart';

class GetContactsUseCase {
  GetContactsUseCase(this._repository);

  final ContactsRepository _repository;

  Future<List<ContactEntity>> call({bool forceRefresh = false}) {
    return _repository.getContacts(forceRefresh: forceRefresh);
  }
}
