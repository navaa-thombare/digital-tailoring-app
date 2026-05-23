import '../../core/utils/app_date_utils.dart';
import '../../core/utils/uuid_utils.dart';
import '../dao/database_dao.dart';

class PermissionRepository extends DatabaseDao {
  Future<List<Map<String, Object?>>> listPermissions() async {
    final database = await db;
    return database.query('permissions', orderBy: 'scope ASC, code ASC');
  }

  Future<void> createPermission({
    required String code,
    required String name,
    required String scope,
    String? description,
  }) async {
    final database = await db;
    await database.insert('permissions', {
      'id': UuidUtils.v4(),
      'code': code.trim().toLowerCase(),
      'name': name.trim(),
      'description': description,
      'scope': scope,
      'is_active': 1,
      'created_at': AppDateUtils.nowIso(),
    });
  }
}
