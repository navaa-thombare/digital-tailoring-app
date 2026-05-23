import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/services/app_providers.dart';
import '../../features/auth/controllers/auth_controller.dart';
import 'app_drawer.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final path = GoRouterState.of(context).matchedLocation;
    final canShow =
        session == null || path == '/profile' || path == '/store-usage-blocked';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: const AppDrawer(),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: canShow
            ? child
            : FutureBuilder<bool>(
                future: ref
                    .watch(permissionServiceProvider)
                    .isStoreExpired(session.storeId),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) context.go('/store-usage-blocked');
                    });
                  }
                  return child;
                },
              ),
      ),
    );
  }
}
