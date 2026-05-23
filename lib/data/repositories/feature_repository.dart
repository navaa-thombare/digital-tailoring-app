import '../../core/utils/app_date_utils.dart';
import '../../core/utils/uuid_utils.dart';
import '../dao/database_dao.dart';

class FeatureRepository extends DatabaseDao {
  Future<List<Map<String, Object?>>> listFeatures() async {
    final database = await db;
    return database.query('features', orderBy: 'name ASC');
  }

  Future<void> createFeature({
    required String code,
    required String name,
    String? description,
  }) async {
    final database = await db;
    await database.insert('features', {
      'id': UuidUtils.v4(),
      'code': code.trim().toLowerCase(),
      'name': name.trim(),
      'description': description,
      'is_active': 1,
      'created_at': AppDateUtils.nowIso(),
    });
  }

  Future<void> setActive(String id, bool active) async {
    final database = await db;
    await database.update(
      'features',
      {'is_active': active ? 1 : 0, 'updated_at': AppDateUtils.nowIso()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
