import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/audit/screens/audit_logs_screen.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/screens/force_password_change_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/profile_screen.dart';
import '../features/dashboard/screens/owner_dashboard_screen.dart';
import '../features/features_console/screens/features_console_screen.dart';
import '../features/licensing/screens/licensing_screen.dart';
import '../features/permissions/screens/permissions_screen.dart';
import '../features/roles/screens/role_edit_screen.dart';
import '../features/roles/screens/roles_console_screen.dart';
import '../features/stores/screens/worker_creation_screen.dart';
import '../features/stores/screens/store_details_screen.dart';
import '../features/stores/screens/store_form_screen.dart';
import '../features/stores/screens/store_list_screen.dart';
import '../features/stores/screens/store_owner_contact_screen.dart';
import '../features/stores/screens/store_usage_blocked_screen.dart';
import '../features/stores/screens/store_usage_period_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final session = authState.value;

  return GoRouter(
    initialLocation: session == null ? '/login' : '/dashboard',
    redirect: (context, state) {
      final isLogin = state.matchedLocation == '/login';
      if (authState.isLoading) return null;
      if (session == null && !isLogin) return '/login';
      if (session != null && isLogin) {
        return session.forcePasswordChange
            ? '/force-password-change'
            : '/dashboard';
      }
      if (session != null &&
          session.forcePasswordChange &&
          state.matchedLocation != '/force-password-change') {
        return '/force-password-change';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/force-password-change',
        builder: (context, state) => const ForcePasswordChangeScreen(),
      ),
      GoRoute(
          path: '/dashboard',
          builder: (context, state) => const OwnerDashboardScreen()),
      GoRoute(
          path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(
          path: '/roles',
          builder: (context, state) => const RolesConsoleScreen()),
      GoRoute(
          path: '/roles/new',
          builder: (context, state) => const RoleEditScreen()),
      GoRoute(
          path: '/permissions',
          builder: (context, state) => const PermissionsScreen()),
      GoRoute(
          path: '/features',
          builder: (context, state) => const FeaturesConsoleScreen()),
      GoRoute(
          path: '/licensing',
          builder: (context, state) => const LicensingScreen()),
      GoRoute(
          path: '/stores',
          builder: (context, state) => const StoreListScreen()),
      GoRoute(
          path: '/stores/new',
          builder: (context, state) => const StoreFormScreen()),
      GoRoute(
        path: '/stores/:storeId',
        builder: (context, state) => StoreDetailsScreen(
          storeId: state.pathParameters['storeId']!,
        ),
      ),
      GoRoute(
        path: '/stores/:storeId/contact-owner',
        builder: (context, state) => StoreOwnerContactScreen(
          storeId: state.pathParameters['storeId']!,
        ),
      ),
      GoRoute(
        path: '/stores/:storeId/workers/new',
        builder: (context, state) => WorkerCreationScreen(
          storeId: state.pathParameters['storeId']!,
        ),
      ),
      GoRoute(
        path: '/stores/:storeId/usage',
        builder: (context, state) => StoreUsagePeriodScreen(
          storeId: state.pathParameters['storeId']!,
        ),
      ),
      GoRoute(
          path: '/audit', builder: (context, state) => const AuditLogsScreen()),
      GoRoute(
        path: '/store-usage-blocked',
        builder: (context, state) => const StoreUsageBlockedScreen(),
      ),
    ],
  );
});
