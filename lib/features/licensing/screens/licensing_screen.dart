import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/services/app_providers.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/data_table_view.dart';
import '../../../shared/widgets/form_field_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/status_badge.dart';

class LicensingScreen extends ConsumerStatefulWidget {
  const LicensingScreen({super.key});

  @override
  ConsumerState<LicensingScreen> createState() => _LicensingScreenState();
}

class _LicensingScreenState extends ConsumerState<LicensingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  int _period = 30;
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(storeTypeRepositoryProvider).listStoreTypes();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(
        () => _future = ref.read(storeTypeRepositoryProvider).listStoreTypes());
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(storeTypeRepositoryProvider).createStoreType(
          code: _code.text,
          name: _name.text,
          defaultUsagePeriodDays: _period,
        );
    _code.clear();
    _name.clear();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Licensing',
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();
          return ListView(
            children: [
              const AppHeader(
                title: 'Licensing Console',
                subtitle:
                    'Store types define default usage limits and features.',
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          FormFieldView(
                              controller: _code,
                              label: 'Store Type Code',
                              validator: _required),
                          const SizedBox(height: 12),
                          FormFieldView(
                              controller: _name,
                              label: 'Name',
                              validator: _required),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: _period,
                            decoration: const InputDecoration(
                                labelText: 'Default Usage Period'),
                            items: AppConstants.allowedUsagePeriods
                                .map((days) => DropdownMenuItem(
                                    value: days, child: Text('$days days')))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _period = value!),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _create,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Store Type'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: DataTableView(
                  columns: const [
                    'Code',
                    'Name',
                    'Default Usage',
                    'Status',
                    'Action'
                  ],
                  rows: snapshot.data!.map((type) {
                    final active = type['is_active'] == 1;
                    return [
                      Text('${type['code']}'),
                      Text('${type['name']}'),
                      Text('${type['default_usage_period_days']} days'),
                      StatusBadge(
                          label: active ? 'Active' : 'Inactive',
                          active: active),
                      IconButton(
                        icon: Icon(active ? Icons.toggle_on : Icons.toggle_off),
                        onPressed: () async {
                          await ref
                              .read(storeTypeRepositoryProvider)
                              .setActive(type['id'] as String, !active);
                          await _reload();
                        },
                      ),
                    ];
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
}
