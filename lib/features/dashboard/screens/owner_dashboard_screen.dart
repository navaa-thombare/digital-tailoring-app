import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/app_providers.dart';
import '../../../domain/services/dashboard_service.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/data_table_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/metric_card.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(dashboardServiceProvider);
    return AppShell(
      title: 'Dashboard',
      child: FutureBuilder<DashboardMetrics>(
        future: service.ownerMetrics(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();
          final metrics = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dashboardServiceProvider),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const AppHeader(
                  title: 'Owner Dashboard',
                  subtitle: 'Shop, worker and audit overview.',
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final itemWidth = width >= 720 ? (width - 24) / 3 : width;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _metric(itemWidth, 'Total Stores',
                              metrics.totalStores, Icons.store),
                          _metric(itemWidth, 'Active Stores',
                              metrics.activeStores, Icons.verified),
                          _metric(itemWidth, 'Inactive Stores',
                              metrics.inactiveStores, Icons.pause_circle),
                          _metric(itemWidth, 'Expired Stores',
                              metrics.expiredStores, Icons.warning),
                          _metric(itemWidth, 'Total Users', metrics.totalUsers,
                              Icons.people),
                          _metric(itemWidth, 'Workers', metrics.totalWorkers,
                              Icons.admin_panel_settings),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DataTableView(
                    columns: const ['Store Type', 'Stores'],
                    rows: metrics.storesByType
                        .map((row) => [
                              Text('${row['name']}'),
                              Text('${row['total']}'),
                            ])
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DataTableView(
                    columns: const ['Recent Store', 'Type', 'Status'],
                    rows: metrics.recentStores
                        .map((row) => [
                              Text('${row['name']}'),
                              Text('${row['store_type_name']}'),
                              Text('${row['status']}'),
                            ])
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DataTableView(
                    columns: const ['Audit Action', 'Entity', 'Created'],
                    rows: metrics.recentAuditLogs
                        .map((row) => [
                              Text('${row['action_type']}'),
                              Text('${row['entity_type']}'),
                              Text('${row['created_at']}'),
                            ])
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metric(double width, String label, int value, IconData icon) {
    return SizedBox(
      width: width,
      child: MetricCard(label: label, value: value.toString(), icon: icon),
    );
  }
}
