import '../errors/app_exception.dart';

enum AppEnvironment { dev, prod }

class AppConfig {
  const AppConfig._();

  static const _environmentValue =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  static const databaseName = 'storemanagement.db';
  static const databaseVersion = 2;

  static AppEnvironment get environment {
    return switch (_environmentValue.toLowerCase()) {
      'prod' || 'production' => AppEnvironment.prod,
      _ => AppEnvironment.dev,
    };
  }

  static bool get isProduction => environment == AppEnvironment.prod;
  static String get ownerDefaultPassword => const String.fromEnvironment(
        'OWNER_DEFAULT_PASSWORD',
        defaultValue: '',
      );
  static String get ownerName => const String.fromEnvironment(
        'OWNER_NAME',
        defaultValue: 'Navaa Tailors',
      );
  static String get shopName => const String.fromEnvironment(
        'SHOP_NAME',
        defaultValue: 'Digital Tailoring Studio',
      );
  static String get ownerPhone => const String.fromEnvironment(
        'OWNER_PHONE',
        defaultValue: '9999999999',
      );
  static String get shopAddress => const String.fromEnvironment(
        'SHOP_ADDRESS',
        defaultValue: 'Shop No. 12, Main Road, Near Landmark',
      );
  static int get sessionTtlDays =>
      int.tryParse(
        const String.fromEnvironment(
          'SESSION_TTL_DAYS',
          defaultValue: '7',
        ),
      ) ??
      7;
  static String get supabaseUrl => _supabaseUrl;
  static String get supabasePublishableKey => _supabasePublishableKey;
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static void validateForStartup() {
    if (!isProduction && ownerDefaultPassword.isEmpty) {
      throw const AppException(
        'OWNER_DEFAULT_PASSWORD is required in config/owner.json.',
      );
    }
    if (!isProduction &&
        (ownerName.isEmpty ||
            shopName.isEmpty ||
            ownerPhone.isEmpty ||
            shopAddress.isEmpty)) {
      throw const AppException(
        'Development builds require owner details in config/owner.json.',
      );
    }
    if (supabaseUrl.isNotEmpty && !supabaseUrl.startsWith('https://')) {
      throw const AppException('SUPABASE_URL must start with https://.');
    }
    if (supabaseUrl.isNotEmpty && supabasePublishableKey.isEmpty) {
      throw const AppException(
        'SUPABASE_PUBLISHABLE_KEY is required when SUPABASE_URL is set.',
      );
    }
    if (isProduction && !hasSupabaseConfig) {
      throw const AppException(
        'Production builds require SUPABASE_URL and '
        'SUPABASE_PUBLISHABLE_KEY.',
      );
    }
  }
}
