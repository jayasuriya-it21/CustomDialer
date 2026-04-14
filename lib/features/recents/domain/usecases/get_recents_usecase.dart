import '../entities/recents_payload.dart';
import '../repositories/recents_repository.dart';

class GetRecentsUseCase {
  GetRecentsUseCase(this._repository);

  final RecentsRepository _repository;

  Future<RecentsPayload> call({bool forceRefresh = false}) {
    return _repository.getRecents(forceRefresh: forceRefresh);
  }
}
