import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final isSuperadmin = session?.isSuperadmin ?? false;
    final currentPath = GoRouterState.of(context).matchedLocation;
    final destinations = _destinations(isSuperadmin);

    Future<void> logout() async {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }

    return NavigationDrawer(
      selectedIndex: _selectedIndex(currentPath, destinations),
      onDestinationSelected: (index) {
        context.go(destinations[index].route);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Store Management',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(session?.fullName ?? '',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        for (final destination in destinations) destination.widget,
        const Padding(padding: EdgeInsets.only(top: 12), child: Divider()),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: logout,
        ),
      ],
    );
  }

  List<_DrawerDestination> _destinations(bool isSuperadmin) {
    return [
      const _DrawerDestination(
        route: '/dashboard',
        widget: NavigationDrawerDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
      ),
      if (isSuperadmin) ...const [
        _DrawerDestination(
          route: '/stores',
          widget: NavigationDrawerDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: Text('Stores'),
          ),
        ),
        _DrawerDestination(
          route: '/roles',
          widget: NavigationDrawerDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: Text('Roles'),
          ),
        ),
        _DrawerDestination(
          route: '/permissions',
          widget: NavigationDrawerDestination(
            icon: Icon(Icons.key_outlined),
            selectedIcon: Icon(Icons.key),
            label: Text('Permissions'),
          ),
        ),
        _DrawerDestination(
          route: '/features',
          widget: NavigationDrawerDestination(
            icon: Icon(Icons.extension_outlined),
            selectedIcon: Icon(Icons.extension),
            label: Text('Features'),
          ),
        ),
        _DrawerDestination(
          route: '/licensing',
          widget: NavigationDrawerDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium),
            label: Text('Licensing'),
          ),
        ),
        _DrawerDestination(
          route: '/audit',
          widget: NavigationDrawerDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: Text('Audit Logs'),
          ),
        ),
      ],
      const _DrawerDestination(
        route: '/profile',
        widget: NavigationDrawerDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Profile'),
        ),
      ),
    ];
  }

  int _selectedIndex(String path, List<_DrawerDestination> destinations) {
    if (path.startsWith('/stores')) {
      final storeIndex =
          destinations.indexWhere((item) => item.route == '/stores');
      return storeIndex < 0 ? 0 : storeIndex;
    }
    final index = destinations.indexWhere((item) => item.route == path);
    return index < 0 ? 0 : index;
  }
}

class _DrawerDestination {
  const _DrawerDestination({required this.route, required this.widget});

  final String route;
  final NavigationDrawerDestination widget;
}
