import 'dart:convert';
import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/uuid_utils.dart';
import '../dao/database_dao.dart';

class StoreUsageRepository extends DatabaseDao {
  Future<Map<String, Object?>?> currentForStore(String storeId) async {
    final database = await db;
    final rows = await database.query(
      'store_usage_limits',
      where: 'store_id = ? AND is_active = 1',
      whereArgs: [storeId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, Object?>>> activeUnexpiredLimits() async {
    final database = await db;
    return database.query(
      'store_usage_limits',
      where: 'is_active = 1 AND is_usage_expired = 0',
    );
  }

  Future<void> applyDailyDecrement({
    required String usageLimitId,
    required String storeId,
    required int remainingDays,
    required int daysPassed,
    required String today,
  }) async {
    final database = await db;
    final newRemaining = max(0, remainingDays - daysPassed);
    final expired = newRemaining == 0;
    await database.transaction((txn) async {
      await txn.update(
        'store_usage_limits',
        {
          'remaining_usage_days': newRemaining,
          'last_usage_decrement_date': today,
          'is_usage_expired': expired ? 1 : 0,
          'updated_at': AppDateUtils.nowIso(),
        },
        where: 'id = ?',
        whereArgs: [usageLimitId],
      );
      if (expired) {
        await txn.update(
          'stores',
          {
            'status': AppConstants.storeStatusExpired,
            'is_active': 0,
            'updated_at': AppDateUtils.nowIso(),
          },
          where: 'id = ?',
          whereArgs: [storeId],
        );
        await txn.insert('audit_logs', {
          'id': UuidUtils.v4(),
          'actor_user_id': null,
          'action_type': 'STORE_USAGE_EXPIRED_AUTOMATICALLY',
          'entity_type': 'stores',
          'entity_id': storeId,
          'new_value': jsonEncode({'remaining_usage_days': 0}),
          'remarks': 'Usage expired during app startup/login decrement.',
          'created_at': AppDateUtils.nowIso(),
        });
      }
    });
  }

  Future<void> updatePeriod({
    required String storeId,
    required int usagePeriodDays,
    required String? actorUserId,
  }) async {
    if (!AppConstants.allowedUsagePeriods.contains(usagePeriodDays)) {
      throw const AppException(
          'Usage period must be 30, 60, 90, 120, 150, or 180 days.');
    }
    final current = await currentForStore(storeId);
    if (current == null) throw const AppException('Usage limit not found.');

    final database = await db;
    final now = AppDateUtils.nowIso();
    final today = AppDateUtils.todayIsoDate();
    final startDate = current['usage_start_date'] as String;
    final daysUsed = max(0, AppDateUtils.daysBetweenIsoDates(startDate, today));
    final newRemaining = max(0, usagePeriodDays - daysUsed);
    final usageEnd = AppDateUtils.addDaysIso(startDate, usagePeriodDays);
    final wasExpired = current['is_usage_expired'] == 1;

    await database.transaction((txn) async {
      await txn.update(
        'store_usage_limits',
        {
          'usage_period_days': usagePeriodDays,
          'usage_end_date': usageEnd,
          'remaining_usage_days': newRemaining,
          'is_usage_expired': newRemaining == 0 ? 1 : 0,
          'last_usage_decrement_date': today,
          'updated_at': now,
          'updated_by': actorUserId,
        },
        where: 'id = ?',
        whereArgs: [current['id']],
      );
      if (wasExpired && newRemaining > 0) {
        await txn.update(
          'stores',
          {
            'status': AppConstants.storeStatusActive,
            'is_active': 1,
            'updated_at': now
          },
          where: 'id = ?',
          whereArgs: [storeId],
        );
      }
      await txn.insert('audit_logs', {
        'id': UuidUtils.v4(),
        'actor_user_id': actorUserId,
        'action_type': 'USAGE_PERIOD_UPDATED',
        'entity_type': 'store_usage_limits',
        'entity_id': current['id'],
        'old_value': jsonEncode(current),
        'new_value': jsonEncode({
          'usage_period_days': usagePeriodDays,
          'remaining_usage_days': newRemaining,
          'usage_end_date': usageEnd,
        }),
        'created_at': now,
      });
      if (wasExpired && newRemaining > 0) {
        await txn.insert('audit_logs', {
          'id': UuidUtils.v4(),
          'actor_user_id': actorUserId,
          'action_type': 'STORE_USAGE_REACTIVATED',
          'entity_type': 'stores',
          'entity_id': storeId,
          'created_at': now,
        });
      }
    });
  }

  Future<void> renew({
    required String storeId,
    required int usagePeriodDays,
    required String? actorUserId,
  }) async {
    if (!AppConstants.allowedUsagePeriods.contains(usagePeriodDays)) {
      throw const AppException(
          'Usage period must be 30, 60, 90, 120, 150, or 180 days.');
    }
    final current = await currentForStore(storeId);
    if (current == null) throw const AppException('Usage limit not found.');

    final database = await db;
    final now = AppDateUtils.nowIso();
    final today = AppDateUtils.todayIsoDate();
    final usageEnd = AppDateUtils.addDaysIso(today, usagePeriodDays);
    await database.transaction((txn) async {
      await txn.update(
        'store_usage_limits',
        {
          'usage_period_days': usagePeriodDays,
          'usage_start_date': today,
          'usage_end_date': usageEnd,
          'remaining_usage_days': usagePeriodDays,
          'last_usage_decrement_date': today,
          'is_usage_expired': 0,
          'updated_at': now,
          'updated_by': actorUserId,
        },
        where: 'id = ?',
        whereArgs: [current['id']],
      );
      await txn.update(
        'stores',
        {
          'status': AppConstants.storeStatusActive,
          'is_active': 1,
          'updated_at': now
        },
        where: 'id = ?',
        whereArgs: [storeId],
      );
      await txn.insert('audit_logs', {
        'id': UuidUtils.v4(),
        'actor_user_id': actorUserId,
        'action_type': 'USAGE_PERIOD_RENEWED',
        'entity_type': 'store_usage_limits',
        'entity_id': current['id'],
        'old_value': jsonEncode(current),
        'new_value': jsonEncode({
          'usage_period_days': usagePeriodDays,
          'usage_start_date': today,
          'usage_end_date': usageEnd,
          'remaining_usage_days': usagePeriodDays,
        }),
        'created_at': now,
      });
    });
  }
}
