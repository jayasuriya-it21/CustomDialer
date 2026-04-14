import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/search_result_entity.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/search_contacts_and_logs_usecase.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._searchUseCase, this._searchRepository) : super(SearchState.initial());

  final SearchContactsAndLogsUseCase _searchUseCase;
  final SearchRepository _searchRepository;

  void initialize() {
    emit(state.copyWith(isLoaded: true));
  }

  Future<void> queryChanged(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(query: query, results: const <SearchResultEntity>[]));
      return;
    }

    final results = await _searchUseCase(trimmed);
    emit(state.copyWith(query: query, results: results));
  }

  Future<void> makeCall(String number) {
    return _searchRepository.makeCall(number);
  }

  Future<void> openSms(String number) {
    return _searchRepository.openSms(number);
  }
}
