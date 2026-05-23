import 'package:sqflite/sqflite.dart';

import '../config/app_config.dart';
import 'app_database_factory.dart';
import 'database_seed.dart';
import 'migration_runner.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databaseFactory = await createAppDatabaseFactory();
    final dbPath = await resolveAppDatabasePath(AppConfig.databaseName);
    _database = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: AppConfig.databaseVersion,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE IF NOT EXISTS schema_migrations (
            version INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            applied_at TEXT NOT NULL
          )
        ''');
          await MigrationRunner().migrate(
            db,
            fromVersion: 0,
            toVersion: version,
          );
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await MigrationRunner().migrate(
            db,
            fromVersion: oldVersion,
            toVersion: newVersion,
          );
        },
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await DatabaseSeed().seed(db);
        },
      ),
    );
    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
