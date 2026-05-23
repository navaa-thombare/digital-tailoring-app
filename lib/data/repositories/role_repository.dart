import 'package:sqflite/sqflite.dart';

import '../../core/utils/app_date_utils.dart';
import '../../core/utils/uuid_utils.dart';
import '../dao/database_dao.dart';

class RoleRepository extends DatabaseDao {
  Future<List<Map<String, Object?>>> listRoles() async {
    final database = await db;
    return database.query('roles', orderBy: 'scope ASC, name ASC');
  }

  Future<void> createRole({
    required String code,
    required String name,
    required String scope,
    String? description,
  }) async {
    final database = await db;
    await database.insert('roles', {
      'id': UuidUtils.v4(),
      'code': code.trim().toLowerCase(),
      'name': name.trim(),
      'description': description,
      'scope': scope,
      'is_system_role': 0,
      'is_active': 1,
      'created_at': AppDateUtils.nowIso(),
    });
  }

  Future<void> setActive(String roleId, bool active) async {
    final database = await db;
    await database.update(
      'roles',
      {'is_active': active ? 1 : 0, 'updated_at': AppDateUtils.nowIso()},
      where: 'id = ?',
      whereArgs: [roleId],
    );
  }

  Future<void> assignPermission(String roleId, String permissionId) async {
    final database = await db;
    await database.insert(
      'role_permissions',
      {
        'id': UuidUtils.v4(),
        'role_id': roleId,
        'permission_id': permissionId,
        'created_at': AppDateUtils.nowIso(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, Object?>>> permissionsForRole(String roleId) async {
    final database = await db;
    return database.rawQuery('''
      SELECT p.*
      FROM permissions p
      INNER JOIN role_permissions rp ON rp.permission_id = p.id
      WHERE rp.role_id = ?
      ORDER BY p.code
    ''', [roleId]);
  }
}
