import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<DatabaseFactory> createAppDatabaseFactory() async {
  return databaseFactoryFfiWeb;
}

Future<String> resolveAppDatabasePath(String databaseName) async {
  return databaseName;
}
