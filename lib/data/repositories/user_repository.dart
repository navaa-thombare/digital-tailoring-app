import 'dart:convert';

import '../../core/security/password_hasher.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/uuid_utils.dart';
import '../dao/database_dao.dart';

class UserRepository extends DatabaseDao {
  Future<List<Map<String, Object?>>> listUsers({String? storeId}) async {
    final database = await db;
    if (storeId == null) {
      return database.query('users', orderBy: 'created_at DESC');
    }
    return database.query(
      'users',
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'created_at DESC',
    );
  }

  Future<String> createWorker({
    required String storeId,
    required String fullName,
    required String email,
    String? mobile,
    required String temporaryPassword,
    String? actorUserId,
  }) async {
    final database = await db;
    final now = AppDateUtils.nowIso();
    final userId = UuidUtils.v4();
    final workerRoleRows = await database.query(
      'roles',
      columns: ['id'],
      where: 'code = ?',
      whereArgs: ['worker'],
      limit: 1,
    );
    final workerRoleId = workerRoleRows.first['id'] as String;
    final passwordHash = const PasswordHasher().hash(temporaryPassword);

    await database.transaction((txn) async {
      await txn.insert('users', {
        'id': userId,
        'store_id': storeId,
        'username': email.trim().toLowerCase(),
        'email': email.trim().toLowerCase(),
        'mobile': mobile,
        'password_hash': passwordHash,
        'full_name': fullName.trim(),
        'is_active': 1,
        'force_password_change': 1,
        'temporary_password': 1,
        'created_at': now,
        'created_by': actorUserId,
      });
      await txn.insert('user_roles', {
        'id': UuidUtils.v4(),
        'user_id': userId,
        'role_id': workerRoleId,
        'store_id': storeId,
        'created_at': now,
      });
      await txn.insert('audit_logs', {
        'id': UuidUtils.v4(),
        'actor_user_id': actorUserId,
        'action_type': 'WORKER_CREATED',
        'entity_type': 'users',
        'entity_id': userId,
        'new_value': jsonEncode({'email': email, 'store_id': storeId}),
        'remarks':
            'Temporary password set; user must change password on first login.',
        'created_at': now,
      });
    });
    return userId;
  }
}
