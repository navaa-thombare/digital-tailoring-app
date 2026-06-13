import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:storemanagement/core/database/migration_runner.dart';

void main() {
  test('database version 4 creates the permanent tailoring state cache',
      () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    addTearDown(database.close);

    await database.execute('''
      CREATE TABLE schema_migrations (
        version INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        applied_at TEXT NOT NULL
      )
    ''');
    await MigrationRunner().migrate(
      database,
      fromVersion: 0,
      toVersion: 4,
    );

    final tables = await database.query(
      'sqlite_master',
      columns: const ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: const ['table', 'tailoring_state_cache'],
    );
    final migrations = await database.query(
      'schema_migrations',
      columns: const ['version'],
      orderBy: 'version',
    );

    expect(tables, hasLength(1));
    expect(
      migrations.map((row) => row['version']),
      orderedEquals([1, 2, 3, 4]),
    );
  });
}
