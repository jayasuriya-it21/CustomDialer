import 'package:equatable/equatable.dart';

import '../../../core/models/contact_entity.dart';

class ContactListItem {
  const ContactListItem._({this.letter, this.contact});

  const ContactListItem.header(String letter) : this._(letter: letter);
  const ContactListItem.contact(ContactEntity contact) : this._(contact: contact);

  final String? letter;
  final ContactEntity? contact;

  bool get isHeader => letter != null;
}

abstract class ContactsState extends Equatable {
  const ContactsState();

  @override
  List<Object?> get props => [];
}

class ContactsInitial extends ContactsState {
  const ContactsInitial();
}

class ContactsLoading extends ContactsState {
  const ContactsLoading();
}

class ContactsLoaded extends ContactsState {
  const ContactsLoaded(this.contacts, {this.groupedItems = const []});

  final List<ContactEntity> contacts;
  final List<ContactListItem> groupedItems;

  @override
  List<Object?> get props => [contacts, groupedItems];
}

class ContactsError extends ContactsState {
  const ContactsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
