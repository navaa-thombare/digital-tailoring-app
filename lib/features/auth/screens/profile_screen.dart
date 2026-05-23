import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final user = session?.user ?? {};
    return AppShell(
      title: 'Profile',
      child: ListView(
        children: [
          const AppHeader(title: 'Current User'),
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user['full_name'] ?? ''}',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Email: ${user['email'] ?? ''}'),
                  Text('Username: ${user['username'] ?? ''}'),
                  Text('Mobile: ${user['mobile'] ?? '-'}'),
                  Text(
                      'Superadmin: ${user['is_superadmin'] == 1 ? 'Yes' : 'No'}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
