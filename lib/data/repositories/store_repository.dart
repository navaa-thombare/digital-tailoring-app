import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/uuid_utils.dart';
import '../dao/database_dao.dart';

class StoreRepository extends DatabaseDao {
  Future<List<Map<String, Object?>>> listStores() async {
    final database = await db;
    return database.rawQuery('''
      SELECT s.*, st.name AS store_type_name, sul.remaining_usage_days,
             sul.is_usage_expired, sul.usage_end_date
      FROM stores s
      INNER JOIN store_types st ON st.id = s.store_type_id
      LEFT JOIN store_usage_limits sul ON sul.store_id = s.id AND sul.is_active = 1
      ORDER BY s.created_at DESC
    ''');
  }

  Future<Map<String, Object?>?> findStore(String storeId) async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT s.*, st.name AS store_type_name, sul.usage_period_days,
             sul.usage_start_date, sul.usage_end_date, sul.remaining_usage_days,
             sul.last_usage_decrement_date, sul.is_usage_expired
      FROM stores s
      INNER JOIN store_types st ON st.id = s.store_type_id
      LEFT JOIN store_usage_limits sul ON sul.store_id = s.id AND sul.is_active = 1
      WHERE s.id = ?
    ''', [storeId]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, Object?>?> contact(String storeId) async {
    final database = await db;
    final rows = await database.query(
      'store_contacts',
      where: 'store_id = ?',
      whereArgs: [storeId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, Object?>>> owners(String storeId) async {
    final database = await db;
    return database.query(
      'store_owners',
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'is_primary_owner DESC, owner_name ASC',
    );
  }

  Future<String> createStore({
    required String storeTypeId,
    required String code,
    required String name,
    required Map<String, Object?> contact,
    required Map<String, Object?> owner,
    required int usagePeriodDays,
    String? actorUserId,
  }) async {
    if (!AppConstants.allowedUsagePeriods.contains(usagePeriodDays)) {
      throw const AppException(
          'Usage period must be 30, 60, 90, 120, 150, or 180 days.');
    }
    final database = await db;
    final storeId = UuidUtils.v4();
    final now = AppDateUtils.nowIso();
    final today = AppDateUtils.todayIsoDate();
    final usageEnd = AppDateUtils.addDaysIso(today, usagePeriodDays);
    await database.transaction((txn) async {
      await txn.insert('stores', {
        'id': storeId,
        'store_type_id': storeTypeId,
        'code': code.trim().toUpperCase(),
        'name': name.trim(),
        'status': AppConstants.storeStatusActive,
        'is_active': 1,
        'created_at': now,
        'created_by': actorUserId,
      });
      await txn.insert('store_contacts', {
        'id': UuidUtils.v4(),
        'store_id': storeId,
        ...contact,
        'created_at': now,
      });
      await txn.insert('store_owners', {
        'id': UuidUtils.v4(),
        'store_id': storeId,
        ...owner,
        'is_primary_owner': 1,
        'created_at': now,
      });
      await txn.insert('store_usage_limits', {
        'id': UuidUtils.v4(),
        'store_id': storeId,
        'usage_period_days': usagePeriodDays,
        'usage_start_date': today,
        'usage_end_date': usageEnd,
        'remaining_usage_days': usagePeriodDays,
        'last_usage_decrement_date': today,
        'is_usage_expired': 0,
        'is_active': 1,
        'created_at': now,
        'created_by': actorUserId,
      });
      await txn.insert('audit_logs', {
        'id': UuidUtils.v4(),
        'actor_user_id': actorUserId,
        'action_type': 'STORE_CREATED',
        'entity_type': 'stores',
        'entity_id': storeId,
        'new_value': jsonEncode({'code': code, 'name': name}),
        'created_at': now,
      });
      await txn.insert('audit_logs', {
        'id': UuidUtils.v4(),
        'actor_user_id': actorUserId,
        'action_type': 'USAGE_PERIOD_CREATED',
        'entity_type': 'store_usage_limits',
        'entity_id': storeId,
        'new_value': jsonEncode({
          'usage_period_days': usagePeriodDays,
          'usage_start_date': today,
          'usage_end_date': usageEnd,
        }),
        'created_at': now,
      });
    });
    return storeId;
  }

  Future<void> saveContactAndOwner({
    required String storeId,
    required Map<String, Object?> contact,
    required Map<String, Object?> owner,
  }) async {
    final database = await db;
    final now = AppDateUtils.nowIso();
    await database.transaction((txn) async {
      await txn.update(
        'store_contacts',
        {...contact, 'updated_at': now},
        where: 'store_id = ?',
        whereArgs: [storeId],
      );
      final owners = await txn.query(
        'store_owners',
        columns: ['id'],
        where: 'store_id = ? AND is_primary_owner = 1',
        whereArgs: [storeId],
        limit: 1,
      );
      if (owners.isEmpty) {
        await txn.insert('store_owners', {
          'id': UuidUtils.v4(),
          'store_id': storeId,
          ...owner,
          'is_primary_owner': 1,
          'created_at': now,
        });
      } else {
        await txn.update(
          'store_owners',
          {...owner, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [owners.first['id']],
        );
      }
    });
  }
}
