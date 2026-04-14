import '../repositories/recents_repository.dart';

class DeleteCallLogUseCase {
  DeleteCallLogUseCase(this._repository);

  final RecentsRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteCallLog(id);
  }
}
