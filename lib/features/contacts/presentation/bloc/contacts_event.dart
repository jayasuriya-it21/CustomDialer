import 'package:equatable/equatable.dart';

abstract class ContactsEvent extends Equatable {
  const ContactsEvent();

  @override
  List<Object?> get props => [];
}

class ContactsRequested extends ContactsEvent {
  const ContactsRequested({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}
