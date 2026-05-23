import 'package:sqflite/sqflite.dart';

import '../utils/app_date_utils.dart';
import 'database_migrations.dart';

class MigrationRunner {
  Future<void> migrate(
    Database db, {
    required int fromVersion,
    required int toVersion,
  }) async {
    const migrations = DatabaseMigrations.all;
    await db.transaction((txn) async {
      for (final migration in migrations) {
        if (migration.version > fromVersion && migration.version <= toVersion) {
          for (final statement in migration.statements) {
            await txn.execute(statement);
          }
          await txn.insert(
            'schema_migrations',
            {
              'version': migration.version,
              'name': migration.name,
              'applied_at': AppDateUtils.nowIso(),
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });
  }
}
