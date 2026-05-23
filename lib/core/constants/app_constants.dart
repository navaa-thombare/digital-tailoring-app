class AppConstants {
  const AppConstants._();

  static const allowedUsagePeriods = <int>[30, 60, 90, 120, 150, 180];

  static const globalScope = 'GLOBAL';
  static const storeScope = 'STORE';

  static const storeStatusActive = 'ACTIVE';
  static const storeStatusInactive = 'INACTIVE';
  static const storeStatusExpired = 'EXPIRED';
}
