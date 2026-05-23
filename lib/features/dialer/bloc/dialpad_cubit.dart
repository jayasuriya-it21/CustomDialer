import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/contact_entity.dart';
import '../../../core/services/dialer_repository.dart';
import 'dialpad_state.dart';

class DialpadCubit extends Cubit<DialpadState> {
  DialpadCubit(this._dialerRepository) : super(DialpadState.initial());

  final DialerRepository _dialerRepository;

  static const Map<String, String> _t9Map = {
    '2': 'abcABC',
    '3': 'defDEF',
    '4': 'ghiGHI',
    '5': 'jklJKL',
    '6': 'mnoMNO',
    '7': 'pqrsPQRS',
    '8': 'tuvTUV',
    '9': 'wxyzWXYZ'
  };

  Future<void> initialize() async {
    final contacts = await _dialerRepository.getContacts();
    final sims = await _dialerRepository.getSimInfo();
    emit(state.copyWith(allContacts: contacts, sims: sims, contactsLoaded: true));
  }

  void onDigitPressed(String digit) {
    final next = '${state.number}$digit';
    emit(state.copyWith(number: next, matchingContacts: _findMatches(next)));
  }

  void onBackspace() {
    if (state.number.isEmpty) {
      return;
    }
    final next = state.number.substring(0, state.number.length - 1);
    emit(state.copyWith(number: next, matchingContacts: _findMatches(next)));
  }

  void onClear() {
    emit(state.copyWith(number: '', matchingContacts: const <ContactEntity>[]));
  }

  Future<void> makeCall() async {
    if (state.number.isEmpty) {
      return;
    }
    await _dialerRepository.makeCall(state.number);
  }

  Future<void> makeCallTo(String number) {
    return _dialerRepository.makeCall(number);
  }

  Future<void> addToContacts() async {
    if (state.number.isEmpty) {
      return;
    }
    await _dialerRepository.addContact(state.number);
  }

  Future<void> openVideoCall() async {
    if (state.number.isEmpty) {
      return;
    }
    await _dialerRepository.openVideoCall(state.number);
  }

  static final RegExp _sanitizeNumberRegExp = RegExp(r'[\s\-\(\)\+]');
  static final RegExp _sanitizeNameRegExp = RegExp(r'[^a-zA-Z]');

  List<ContactEntity> _findMatches(String number) {
    if (!state.contactsLoaded || number.isEmpty) {
      return const <ContactEntity>[];
    }

    return state.allContacts
        .where((contact) {
          if (contact.number.replaceAll(_sanitizeNumberRegExp, '').contains(number)) {
            return true;
          }
          return _matchesT9(contact.name, number);
        })
        .take(10)
        .toList();
  }

  bool _matchesT9(String name, String digits) {
    if (name.isEmpty || digits.isEmpty) {
      return false;
    }
    final cleanName = name.replaceAll(_sanitizeNameRegExp, '').toLowerCase();
    if (cleanName.length < digits.length) {
      return false;
    }

    for (var i = 0; i < digits.length; i++) {
      final d = digits[i];
      final letters = _t9Map[d];
      if (letters == null) {
        continue;
      }
      if (i >= cleanName.length) {
        return false;
      }
      if (!letters.toLowerCase().contains(cleanName[i])) {
        return false;
      }
    }
    return true;
  }
}
