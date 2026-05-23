import '../../core/utils/app_date_utils.dart';
import '../../core/utils/uuid_utils.dart';
import '../dao/database_dao.dart';

class StoreTypeRepository extends DatabaseDao {
  Future<List<Map<String, Object?>>> listStoreTypes() async {
    final database = await db;
    return database.query('store_types', orderBy: 'name ASC');
  }

  Future<void> createStoreType({
    required String code,
    required String name,
    required int defaultUsagePeriodDays,
    String? description,
  }) async {
    final database = await db;
    await database.insert('store_types', {
      'id': UuidUtils.v4(),
      'code': code.trim().toLowerCase(),
      'name': name.trim(),
      'description': description,
      'default_usage_period_days': defaultUsagePeriodDays,
      'is_active': 1,
      'created_at': AppDateUtils.nowIso(),
    });
  }

  Future<void> setActive(String id, bool active) async {
    final database = await db;
    await database.update(
      'store_types',
      {'is_active': active ? 1 : 0, 'updated_at': AppDateUtils.nowIso()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
