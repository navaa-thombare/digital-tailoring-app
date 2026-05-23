import '../../core/utils/app_date_utils.dart';
import '../../core/utils/uuid_utils.dart';
import '../dao/database_dao.dart';

class AuditLogRepository extends DatabaseDao {
  Future<void> add({
    String? actorUserId,
    required String actionType,
    required String entityType,
    String? entityId,
    String? oldValue,
    String? newValue,
    String? remarks,
  }) async {
    final database = await db;
    await database.insert('audit_logs', {
      'id': UuidUtils.v4(),
      'actor_user_id': actorUserId,
      'action_type': actionType,
      'entity_type': entityType,
      'entity_id': entityId,
      'old_value': oldValue,
      'new_value': newValue,
      'remarks': remarks,
      'created_at': AppDateUtils.nowIso(),
    });
  }

  Future<List<Map<String, Object?>>> recent({int limit = 50}) async {
    final database = await db;
    return database.rawQuery('''
      SELECT a.*, u.full_name AS actor_name
      FROM audit_logs a
      LEFT JOIN users u ON u.id = a.actor_user_id
      ORDER BY a.created_at DESC
      LIMIT ?
    ''', [limit]);
  }
}
