import 'package:sqflite/sqflite.dart';

import '../../data/dao/database_dao.dart';

class DashboardMetrics {
  const DashboardMetrics({
    required this.totalStores,
    required this.activeStores,
    required this.inactiveStores,
    required this.expiredStores,
    required this.totalUsers,
    required this.totalStoreAdmins,
    required this.storesByType,
    required this.recentStores,
    required this.recentAuditLogs,
  });

  final int totalStores;
  final int activeStores;
  final int inactiveStores;
  final int expiredStores;
  final int totalUsers;
  final int totalStoreAdmins;
  final List<Map<String, Object?>> storesByType;
  final List<Map<String, Object?>> recentStores;
  final List<Map<String, Object?>> recentAuditLogs;
}

class DashboardService extends DatabaseDao {
  Future<DashboardMetrics> superadminMetrics() async {
    final database = await db;
    Future<int> count(String sql, [List<Object?> args = const []]) async {
      return Sqflite.firstIntValue(await database.rawQuery(sql, args)) ?? 0;
    }

    final storesByType = await database.rawQuery('''
      SELECT st.name, COUNT(s.id) AS total
      FROM store_types st
      LEFT JOIN stores s ON s.store_type_id = st.id
      GROUP BY st.id, st.name
      ORDER BY st.name
    ''');
    final recentStores = await database.rawQuery('''
      SELECT s.code, s.name, s.status, s.created_at, st.name AS store_type_name
      FROM stores s
      INNER JOIN store_types st ON st.id = s.store_type_id
      ORDER BY s.created_at DESC
      LIMIT 5
    ''');
    final recentAuditLogs = await database.rawQuery('''
      SELECT action_type, entity_type, created_at
      FROM audit_logs
      ORDER BY created_at DESC
      LIMIT 5
    ''');

    return DashboardMetrics(
      totalStores: await count('SELECT COUNT(1) FROM stores'),
      activeStores: await count(
          'SELECT COUNT(1) FROM stores WHERE status = ?', ['ACTIVE']),
      inactiveStores: await count(
          'SELECT COUNT(1) FROM stores WHERE status = ?', ['INACTIVE']),
      expiredStores: await count(
          'SELECT COUNT(1) FROM stores WHERE status = ?', ['EXPIRED']),
      totalUsers: await count('SELECT COUNT(1) FROM users'),
      totalStoreAdmins: await count('''
        SELECT COUNT(DISTINCT u.id)
        FROM users u
        INNER JOIN user_roles ur ON ur.user_id = u.id
        INNER JOIN roles r ON r.id = ur.role_id
        WHERE r.code = 'admin'
      '''),
      storesByType: storesByType,
      recentStores: recentStores,
      recentAuditLogs: recentAuditLogs,
    );
  }
}
