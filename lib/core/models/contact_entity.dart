import 'package:equatable/equatable.dart';

class ContactEntity extends Equatable {
  const ContactEntity({required this.contactId, required this.name, required this.number});

  final String contactId;
  final String name;
  final String number;

  @override
  List<Object?> get props => [contactId, name, number];
}
