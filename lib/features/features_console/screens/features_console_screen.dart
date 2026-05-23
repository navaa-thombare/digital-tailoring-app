import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/app_providers.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/data_table_view.dart';
import '../../../shared/widgets/form_field_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/status_badge.dart';

class FeaturesConsoleScreen extends ConsumerStatefulWidget {
  const FeaturesConsoleScreen({super.key});

  @override
  ConsumerState<FeaturesConsoleScreen> createState() =>
      _FeaturesConsoleScreenState();
}

class _FeaturesConsoleScreenState extends ConsumerState<FeaturesConsoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(featureRepositoryProvider).listFeatures();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(
        () => _future = ref.read(featureRepositoryProvider).listFeatures());
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(featureRepositoryProvider)
        .createFeature(code: _code.text, name: _name.text);
    _code.clear();
    _name.clear();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Features',
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();
          return ListView(
            children: [
              const AppHeader(title: 'Features Console'),
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
                              label: 'Feature Code',
                              validator: _required),
                          const SizedBox(height: 12),
                          FormFieldView(
                              controller: _name,
                              label: 'Name',
                              validator: _required),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _create,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Feature'),
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
                  columns: const ['Code', 'Name', 'Status', 'Action'],
                  rows: snapshot.data!.map((feature) {
                    final active = feature['is_active'] == 1;
                    return [
                      Text('${feature['code']}'),
                      Text('${feature['name']}'),
                      StatusBadge(
                          label: active ? 'Active' : 'Inactive',
                          active: active),
                      IconButton(
                        icon: Icon(active ? Icons.toggle_on : Icons.toggle_off),
                        onPressed: () async {
                          await ref
                              .read(featureRepositoryProvider)
                              .setActive(feature['id'] as String, !active);
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
