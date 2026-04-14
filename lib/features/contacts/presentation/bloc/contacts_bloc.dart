import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_contacts_usecase.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  ContactsBloc(this._getContactsUseCase) : super(const ContactsInitial()) {
    on<ContactsRequested>(_onContactsRequested);
  }

  final GetContactsUseCase _getContactsUseCase;

  Future<void> _onContactsRequested(ContactsRequested event, Emitter<ContactsState> emit) async {
    emit(const ContactsLoading());
    try {
      final contacts = await _getContactsUseCase(forceRefresh: event.forceRefresh);
      emit(ContactsLoaded(contacts));
    } catch (_) {
      emit(const ContactsError('Unable to load contacts'));
    }
  }
}
