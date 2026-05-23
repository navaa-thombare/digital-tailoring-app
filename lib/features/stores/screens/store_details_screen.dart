import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/app_providers.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/status_badge.dart';

class StoreDetailsScreen extends ConsumerWidget {
  const StoreDetailsScreen({super.key, required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShell(
      title: 'Store Details',
      child: FutureBuilder<Map<String, Object?>?>(
        future: ref.watch(storeRepositoryProvider).findStore(storeId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingView();
          }
          final store = snapshot.data;
          if (store == null) {
            return const Center(child: Text('Store not found.'));
          }
          final expired =
              store['is_usage_expired'] == 1 || store['status'] == 'EXPIRED';
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AppHeader(
                title: '${store['name']}',
                subtitle: '${store['code']} • ${store['store_type_name']}',
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusBadge(
                            label: '${store['status']}', active: !expired),
                        const SizedBox(height: 16),
                        Text(
                            'Usage Period: ${store['usage_period_days']} days'),
                        Text('Usage Start: ${store['usage_start_date']}'),
                        Text('Usage End: ${store['usage_end_date']}'),
                        Text(
                            'Remaining Days: ${store['remaining_usage_days']}'),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: () =>
                                  context.go('/stores/$storeId/contact-owner'),
                              icon: const Icon(Icons.contact_mail),
                              label: const Text('Owner / Contact'),
                            ),
                            FilledButton.icon(
                              onPressed: () =>
                                  context.go('/stores/$storeId/workers/new'),
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Text('Create Worker'),
                            ),
                            FilledButton.icon(
                              onPressed: () =>
                                  context.go('/stores/$storeId/usage'),
                              icon: const Icon(Icons.event_available),
                              label: const Text('Usage Period'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
