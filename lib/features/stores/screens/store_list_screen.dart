import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/app_providers.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/data_table_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/status_badge.dart';

class StoreListScreen extends ConsumerStatefulWidget {
  const StoreListScreen({super.key});

  @override
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends ConsumerState<StoreListScreen> {
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(storeRepositoryProvider).listStores();
  }

  Future<void> _reload() async {
    setState(() => _future = ref.read(storeRepositoryProvider).listStores());
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Stores',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/stores/new'),
        icon: const Icon(Icons.add_business),
        label: const Text('Store'),
      ),
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                const AppHeader(title: 'Store Console'),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DataTableView(
                    columns: const [
                      'Code',
                      'Name',
                      'Type',
                      'Usage',
                      'Status',
                      'Open'
                    ],
                    rows: snapshot.data!.map((store) {
                      final status = '${store['status']}';
                      return [
                        Text('${store['code']}'),
                        Text('${store['name']}'),
                        Text('${store['store_type_name']}'),
                        Text('${store['remaining_usage_days'] ?? '-'} days'),
                        StatusBadge(label: status, active: status == 'ACTIVE'),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => context.go('/stores/${store['id']}'),
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
