import '../../../../services/call_service.dart';
import '../../../../services/contact_service.dart';
import '../../../contacts/domain/repositories/contacts_repository.dart';
import '../../domain/entities/search_result_entity.dart';
import '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._contactsRepository, this._callService, this._contactService);

  final ContactsRepository _contactsRepository;
  final CallService _callService;
  final ContactService _contactService;

  @override
  Future<bool> makeCall(String number) {
    return _callService.makeCall(number);
  }

  @override
  Future<void> openSms(String number) {
    return _contactService.openSms(number);
  }

  @override
  Future<List<SearchResultEntity>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return const <SearchResultEntity>[];
    }

    final contacts = await _contactsRepository.getContacts();
    final logs = await _callService.getCallLog();

    final seen = <String>{};
    final results = <SearchResultEntity>[];

    for (final contact in contacts) {
      final name = contact.name.toLowerCase();
      if (name.contains(q) || contact.number.contains(q)) {
        final key = '$name|${contact.number}';
        if (seen.add(key)) {
          results.add(SearchResultEntity(name: contact.name, number: contact.number, source: 'contact'));
        }
      }
    }

    for (final log in logs) {
      final name = (log['name'] as String? ?? '').toLowerCase();
      final number = log['number']?.toString() ?? '';
      if (name.contains(q) || number.contains(q)) {
        final key = '$name|$number';
        if (seen.add(key)) {
          results.add(SearchResultEntity(name: log['name']?.toString() ?? '', number: number, source: 'log'));
        }
      }
    }

    return results.take(20).toList();
  }
}
