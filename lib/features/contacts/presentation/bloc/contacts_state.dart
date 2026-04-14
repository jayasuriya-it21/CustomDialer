import 'package:equatable/equatable.dart';

import '../../domain/entities/contact_entity.dart';

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
  const ContactsLoaded(this.contacts);

  final List<ContactEntity> contacts;

  @override
  List<Object?> get props => [contacts];
}

class ContactsError extends ContactsState {
  const ContactsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
