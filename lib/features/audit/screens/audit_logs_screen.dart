import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/app_providers.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/data_table_view.dart';
import '../../../shared/widgets/loading_view.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShell(
      title: 'Audit Logs',
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: ref.watch(auditLogRepositoryProvider).recent(limit: 100),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();
          return ListView(
            children: [
              const AppHeader(title: 'Audit Logs'),
              Padding(
                padding: const EdgeInsets.all(16),
                child: DataTableView(
                  columns: const ['Action', 'Entity', 'Actor', 'Created'],
                  rows: snapshot.data!
                      .map((log) => [
                            Text('${log['action_type']}'),
                            Text('${log['entity_type']}'),
                            Text('${log['actor_name'] ?? '-'}'),
                            Text('${log['created_at']}'),
                          ])
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
