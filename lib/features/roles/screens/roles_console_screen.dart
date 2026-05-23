import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/app_providers.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/data_table_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/status_badge.dart';

class RolesConsoleScreen extends ConsumerStatefulWidget {
  const RolesConsoleScreen({super.key});

  @override
  ConsumerState<RolesConsoleScreen> createState() => _RolesConsoleScreenState();
}

class _RolesConsoleScreenState extends ConsumerState<RolesConsoleScreen> {
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(roleRepositoryProvider).listRoles();
  }

  Future<void> _reload() async {
    setState(() => _future = ref.read(roleRepositoryProvider).listRoles());
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Roles',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/roles/new'),
        icon: const Icon(Icons.add),
        label: const Text('Role'),
      ),
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();
          final roles = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                const AppHeader(
                  title: 'Roles Console',
                  subtitle: 'Manage global and store-specific role activation.',
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DataTableView(
                    columns: const [
                      'Code',
                      'Name',
                      'Scope',
                      'Status',
                      'Action'
                    ],
                    rows: roles.map((role) {
                      final active = role['is_active'] == 1;
                      return [
                        Text('${role['code']}'),
                        Text('${role['name']}'),
                        Text('${role['scope']}'),
                        StatusBadge(
                            label: active ? 'Active' : 'Inactive',
                            active: active),
                        IconButton(
                          tooltip: active ? 'Deactivate' : 'Activate',
                          icon:
                              Icon(active ? Icons.toggle_on : Icons.toggle_off),
                          onPressed: () async {
                            await ref
                                .read(roleRepositoryProvider)
                                .setActive(role['id'] as String, !active);
                            await _reload();
                          },
                        ),
                      ];
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
