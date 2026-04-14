import 'package:equatable/equatable.dart';

import '../../../contacts/domain/entities/contact_entity.dart';
import '../../domain/entities/sim_info_entity.dart';

class DialpadState extends Equatable {
  const DialpadState({required this.number, required this.allContacts, required this.matchingContacts, required this.sims, required this.contactsLoaded});

  final String number;
  final List<ContactEntity> allContacts;
  final List<ContactEntity> matchingContacts;
  final List<SimInfoEntity> sims;
  final bool contactsLoaded;

  factory DialpadState.initial() => const DialpadState(number: '', allContacts: <ContactEntity>[], matchingContacts: <ContactEntity>[], sims: <SimInfoEntity>[], contactsLoaded: false);

  DialpadState copyWith({String? number, List<ContactEntity>? allContacts, List<ContactEntity>? matchingContacts, List<SimInfoEntity>? sims, bool? contactsLoaded}) {
    return DialpadState(number: number ?? this.number, allContacts: allContacts ?? this.allContacts, matchingContacts: matchingContacts ?? this.matchingContacts, sims: sims ?? this.sims, contactsLoaded: contactsLoaded ?? this.contactsLoaded);
  }

  @override
  List<Object?> get props => [number, allContacts, matchingContacts, sims, contactsLoaded];
}
