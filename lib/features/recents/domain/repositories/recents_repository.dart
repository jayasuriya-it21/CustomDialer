import '../entities/recents_payload.dart';

abstract class RecentsRepository {
  Future<RecentsPayload> getRecents({bool forceRefresh = false});
  Future<void> deleteCallLog(String id);
}
