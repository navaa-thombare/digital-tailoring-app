import '../../data/repositories/audit_log_repository.dart';

class AuditLogService {
  AuditLogService({AuditLogRepository? repository})
      : _repository = repository ?? AuditLogRepository();

  final AuditLogRepository _repository;

  Future<void> record({
    String? actorUserId,
    required String actionType,
    required String entityType,
    String? entityId,
    String? oldValue,
    String? newValue,
    String? remarks,
  }) {
    return _repository.add(
      actorUserId: actorUserId,
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      oldValue: oldValue,
      newValue: newValue,
      remarks: remarks,
    );
  }
}
