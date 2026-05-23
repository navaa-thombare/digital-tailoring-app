import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/audit_log_repository.dart';
import '../../data/repositories/feature_repository.dart';
import '../../data/repositories/permission_repository.dart';
import '../../data/repositories/role_repository.dart';
import '../../data/repositories/store_repository.dart';
import '../../data/repositories/store_type_repository.dart';
import '../../data/repositories/store_usage_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'auth_service.dart';
import 'dashboard_service.dart';
import 'permission_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final permissionServiceProvider =
    Provider<PermissionService>((ref) => PermissionService());
final dashboardServiceProvider =
    Provider<DashboardService>((ref) => DashboardService());
final roleRepositoryProvider =
    Provider<RoleRepository>((ref) => RoleRepository());
final permissionRepositoryProvider =
    Provider<PermissionRepository>((ref) => PermissionRepository());
final featureRepositoryProvider =
    Provider<FeatureRepository>((ref) => FeatureRepository());
final storeTypeRepositoryProvider =
    Provider<StoreTypeRepository>((ref) => StoreTypeRepository());
final storeRepositoryProvider =
    Provider<StoreRepository>((ref) => StoreRepository());
final storeUsageRepositoryProvider =
    Provider<StoreUsageRepository>((ref) => StoreUsageRepository());
final userRepositoryProvider =
    Provider<UserRepository>((ref) => UserRepository());
final auditLogRepositoryProvider =
    Provider<AuditLogRepository>((ref) => AuditLogRepository());
