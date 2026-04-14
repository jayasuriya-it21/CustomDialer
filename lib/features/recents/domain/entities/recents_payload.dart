import '../../../contacts/domain/entities/contact_entity.dart';
import 'call_log_entity.dart';

class RecentsPayload {
  const RecentsPayload({required this.logs, required this.favorites});

  final List<CallLogEntity> logs;
  final List<ContactEntity> favorites;
}
