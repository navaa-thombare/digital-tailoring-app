import '../../core/config/app_config.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/uuid_utils.dart';
import '../dao/database_dao.dart';

class AuthRepository extends DatabaseDao {
  Future<Map<String, Object?>?> findUserByIdentifier(String identifier) async {
    final database = await db;
    final rows = await database.query(
      'users',
      where:
          'lower(username) = lower(?) OR lower(email) = lower(?) OR mobile = ?',
      whereArgs: [identifier, identifier, identifier],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, Object?>?> findUserById(String id) async {
    final database = await db;
    final rows = await database.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<String> createSession(String userId) async {
    final database = await db;
    final now = DateTime.now().toUtc();
    final token = UuidUtils.v4();
    await database.insert('login_sessions', {
      'id': UuidUtils.v4(),
      'user_id': userId,
      'session_token': token,
      'created_at': AppDateUtils.nowIso(),
      'expires_at': AppDateUtils.dateIso(
          now.add(Duration(days: AppConfig.sessionTtlDays))),
      'is_active': 1,
    });
    await database.update(
      'users',
      {'last_login_at': AppDateUtils.nowIso()},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return token;
  }

  Future<void> revokeSession(String token) async {
    final database = await db;
    await database.update(
      'login_sessions',
      {
        'revoked_at': AppDateUtils.nowIso(),
        'is_active': 0,
      },
      where: 'session_token = ?',
      whereArgs: [token],
    );
  }

  Future<void> updatePassword({
    required String userId,
    required String passwordHash,
  }) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.update(
        'users',
        {
          'password_hash': passwordHash,
          'force_password_change': 0,
          'temporary_password': 0,
          'updated_at': AppDateUtils.nowIso(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
      await txn.insert('user_password_history', {
        'id': UuidUtils.v4(),
        'user_id': userId,
        'password_hash': passwordHash,
        'created_at': AppDateUtils.nowIso(),
      });
    });
  }
}
