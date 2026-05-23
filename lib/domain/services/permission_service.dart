import '../../core/constants/app_constants.dart';
import '../../data/dao/database_dao.dart';

class PermissionService extends DatabaseDao {
  Future<Set<String>> permissionsForUser(String userId) async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT DISTINCT p.code
      FROM permissions p
      INNER JOIN role_permissions rp ON rp.permission_id = p.id
      INNER JOIN user_roles ur ON ur.role_id = rp.role_id
      INNER JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = ?
        AND p.is_active = 1
        AND r.is_active = 1
    ''', [userId]);
    return rows.map((row) => row['code'] as String).toSet();
  }

  Future<bool> hasPermission(String userId, String permissionCode) async {
    final permissions = await permissionsForUser(userId);
    return permissions.contains(permissionCode);
  }

  Future<bool> hasAnyPermission(
      String userId, List<String> permissionCodes) async {
    final permissions = await permissionsForUser(userId);
    return permissionCodes.any(permissions.contains);
  }

  Future<bool> isStoreExpired(String? storeId) async {
    if (storeId == null) return false;
    final database = await db;
    final rows = await database.query(
      'stores',
      columns: ['status'],
      where: 'id = ?',
      whereArgs: [storeId],
      limit: 1,
    );
    return rows.isNotEmpty &&
        rows.first['status'] == AppConstants.storeStatusExpired;
  }

  Future<bool> canAccessRoute({
    required String userId,
    required bool isSuperadmin,
    required String? storeId,
    required String routePath,
  }) async {
    if (isSuperadmin) return true;
    if (await isStoreExpired(storeId)) {
      return routePath == '/store-usage-blocked' || routePath == '/profile';
    }
    final required = _routePermissions[routePath];
    if (required == null) return true;
    return hasAnyPermission(userId, required);
  }

  static const _routePermissions = <String, List<String>>{
    '/dashboard': ['dashboard.global.view', 'store.dashboard.view'],
    '/stores': ['stores.view'],
    '/roles': ['roles.view'],
    '/permissions': ['permissions.view'],
    '/features': ['features.view'],
    '/licensing': ['store_types.view'],
    '/audit': ['audit_logs.view'],
  };
}
