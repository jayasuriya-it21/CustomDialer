import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/contacts_repository.dart';
import '../../../core/models/contact_entity.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  ContactsBloc(this._contactsRepository) : super(const ContactsInitial()) {
    on<ContactsRequested>(_onContactsRequested);
  }

  final ContactsRepository _contactsRepository;

  Future<void> _onContactsRequested(ContactsRequested event, Emitter<ContactsState> emit) async {
    emit(const ContactsLoading());
    try {
      final contacts = await _contactsRepository.getContacts(forceRefresh: event.forceRefresh);

      // Grouping is O(n) for ~2000 contacts (<5ms) — direct execution
      // is faster than compute() which has ~15ms isolate spawn overhead.
      final groupedItems = _buildGroupedItems(contacts);

      emit(ContactsLoaded(contacts, groupedItems: groupedItems));
    } catch (_) {
      emit(const ContactsError('Unable to load contacts'));
    }
  }

  static List<ContactListItem> _buildGroupedItems(List<ContactEntity> contacts) {
    final grouped = <String, List<ContactEntity>>{};
    for (final contact in contacts) {
      final letter = contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '#';
      grouped.putIfAbsent(letter, () => []).add(contact);
    }

    final keys = grouped.keys.toList()..sort();
    final items = <ContactListItem>[];
    for (final key in keys) {
      items.add(ContactListItem.header(key));
      for (final contact in grouped[key]!) {
        items.add(ContactListItem.contact(contact));
      }
    }

    return items;
  }
}
