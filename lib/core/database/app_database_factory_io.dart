import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

Future<DatabaseFactory> createAppDatabaseFactory() async {
  return databaseFactory;
}

Future<String> resolveAppDatabasePath(String databaseName) async {
  final directory = await getApplicationDocumentsDirectory();
  return p.join(directory.path, databaseName);
}
