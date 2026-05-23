import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';

abstract class DatabaseDao {
  Future<Database> get db => AppDatabase.instance.database;
}
