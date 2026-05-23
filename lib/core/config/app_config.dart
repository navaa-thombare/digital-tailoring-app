import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../errors/app_exception.dart';

class AppConfig {
  const AppConfig._();

  static const databaseName = 'storemanagement.db';
  static const databaseVersion = 2;

  static String get superadminUsername =>
      dotenv.env['SUPERADMIN_USERNAME'] ?? 'superadmin';
  static String get superadminEmail =>
      dotenv.env['SUPERADMIN_EMAIL'] ?? 'superadmin@local.store';
  static String? get superadminMobile => dotenv.env['SUPERADMIN_MOBILE'];
  static String get superadminFullName =>
      dotenv.env['SUPERADMIN_FULL_NAME'] ?? 'Default Superadmin';
  static String get superadminDefaultPassword =>
      dotenv.env['SUPERADMIN_DEFAULT_PASSWORD'] ?? '';
  static int get sessionTtlDays =>
      int.tryParse(dotenv.env['SESSION_TTL_DAYS'] ?? '') ?? 7;
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static void validateForStartup() {
    if (superadminDefaultPassword.isEmpty) {
      throw const AppException(
        'SUPERADMIN_DEFAULT_PASSWORD is required in .env for first-time seed.',
      );
    }
    if (supabaseUrl.isNotEmpty && !supabaseUrl.startsWith('https://')) {
      throw const AppException('SUPABASE_URL must start with https://.');
    }
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isEmpty) {
      throw const AppException(
        'SUPABASE_ANON_KEY is required when SUPABASE_URL is set.',
      );
    }
  }
}
