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

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  String _scope = AppConstants.storeScope;
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(permissionRepositoryProvider).listPermissions();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() =>
        _future = ref.read(permissionRepositoryProvider).listPermissions());
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(permissionRepositoryProvider).createPermission(
            code: _code.text,
            name: _name.text,
            scope: _scope,
          );
      _code.clear();
      _name.clear();
      await _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission code must be unique.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Permissions',
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const AppHeader(title: 'Permission Management'),
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
                              label: 'Permission Code',
                              validator: _required),
                          const SizedBox(height: 12),
                          FormFieldView(
                              controller: _name,
                              label: 'Name',
                              validator: _required),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _scope,
                            decoration:
                                const InputDecoration(labelText: 'Scope'),
                            items: const [
                              DropdownMenuItem(
                                  value: AppConstants.globalScope,
                                  child: Text('GLOBAL')),
                              DropdownMenuItem(
                                  value: AppConstants.storeScope,
                                  child: Text('STORE')),
                            ],
                            onChanged: (value) =>
                                setState(() => _scope = value!),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _create,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Permission'),
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
                  columns: const ['Code', 'Name', 'Scope', 'Status'],
                  rows: snapshot.data!
                      .map((item) => [
                            Text('${item['code']}'),
                            Text('${item['name']}'),
                            Text('${item['scope']}'),
                            StatusBadge(
                              label: item['is_active'] == 1
                                  ? 'Active'
                                  : 'Inactive',
                              active: item['is_active'] == 1,
                            ),
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

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
}
