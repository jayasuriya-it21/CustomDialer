import '../entities/search_result_entity.dart';
import '../repositories/search_repository.dart';

class SearchContactsAndLogsUseCase {
  SearchContactsAndLogsUseCase(this._repository);

  final SearchRepository _repository;

  Future<List<SearchResultEntity>> call(String query) {
    return _repository.search(query);
  }
}
