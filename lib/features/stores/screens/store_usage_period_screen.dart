import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../domain/services/app_providers.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/status_badge.dart';

class StoreUsagePeriodScreen extends ConsumerStatefulWidget {
  const StoreUsagePeriodScreen({super.key, required this.storeId});

  final String storeId;

  @override
  ConsumerState<StoreUsagePeriodScreen> createState() =>
      _StoreUsagePeriodScreenState();
}

class _StoreUsagePeriodScreenState
    extends ConsumerState<StoreUsagePeriodScreen> {
  late Future<Map<String, Object?>?> _future;
  int _period = 30;
  bool _periodInitialized = false;

  @override
  void initState() {
    super.initState();
    _future =
        ref.read(storeUsageRepositoryProvider).currentForStore(widget.storeId);
  }

  Future<void> _reload() async {
    setState(() {
      _periodInitialized = false;
      _future = ref
          .read(storeUsageRepositoryProvider)
          .currentForStore(widget.storeId);
    });
  }

  Future<void> _update() async {
    final actor = ref.read(authControllerProvider).value?.userId;
    await ref.read(storeUsageRepositoryProvider).updatePeriod(
          storeId: widget.storeId,
          usagePeriodDays: _period,
          actorUserId: actor,
        );
    await _reload();
  }

  Future<void> _renew() async {
    final actor = ref.read(authControllerProvider).value?.userId;
    await ref.read(storeUsageRepositoryProvider).renew(
          storeId: widget.storeId,
          usagePeriodDays: _period,
          actorUserId: actor,
        );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final isSuperadmin =
        ref.watch(authControllerProvider).value?.isSuperadmin ?? false;
    return AppShell(
      title: 'Usage Period',
      child: FutureBuilder<Map<String, Object?>?>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingView();
          }
          final usage = snapshot.data;
          if (usage == null) {
            return const Center(child: Text('Usage limit not found.'));
          }
          if (!_periodInitialized) {
            _period = usage['usage_period_days'] as int;
            _periodInitialized = true;
          }
          final expired = usage['is_usage_expired'] == 1;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AppHeader(title: 'Usage Period'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusBadge(
                          label: expired ? 'Expired' : 'Active',
                          active: !expired),
                      const SizedBox(height: 16),
                      Text(
                          'Current Usage Period: ${usage['usage_period_days']} days'),
                      Text('Usage Start Date: ${usage['usage_start_date']}'),
                      Text('Usage End Date: ${usage['usage_end_date']}'),
                      Text(
                          'Remaining Usage Days: ${usage['remaining_usage_days']}'),
                      Text(
                          'Last Decrement: ${usage['last_usage_decrement_date'] ?? '-'}'),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        initialValue: _period,
                        decoration: const InputDecoration(
                            labelText: 'Editable Usage Period'),
                        items: AppConstants.allowedUsagePeriods
                            .map((days) => DropdownMenuItem(
                                value: days, child: Text('$days days')))
                            .toList(),
                        onChanged: isSuperadmin
                            ? (value) => setState(() => _period = value!)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      if (isSuperadmin)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: _update,
                              icon: const Icon(Icons.update),
                              label: const Text('Update Usage Period'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _renew,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Renew Usage'),
                            ),
                          ],
                        )
                      else
                        const Text(
                            'Only superadmin can update or renew usage period.'),
                    ],
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
