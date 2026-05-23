import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/services/app_providers.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/form_field_view.dart';

class RoleEditScreen extends ConsumerStatefulWidget {
  const RoleEditScreen({super.key});

  @override
  ConsumerState<RoleEditScreen> createState() => _RoleEditScreenState();
}

class _RoleEditScreenState extends ConsumerState<RoleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _scope = AppConstants.storeScope;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(roleRepositoryProvider).createRole(
            code: _code.text,
            name: _name.text,
            scope: _scope,
            description: _description.text,
          );
      if (mounted) context.go('/roles');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role code must be unique.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'New Role',
      child: ListView(
        children: [
          const AppHeader(title: 'Create Role'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  FormFieldView(
                      controller: _code, label: 'Code', validator: _required),
                  const SizedBox(height: 12),
                  FormFieldView(
                      controller: _name, label: 'Name', validator: _required),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _scope,
                    decoration: const InputDecoration(labelText: 'Scope'),
                    items: const [
                      DropdownMenuItem(
                          value: AppConstants.globalScope,
                          child: Text('GLOBAL')),
                      DropdownMenuItem(
                          value: AppConstants.storeScope, child: Text('STORE')),
                    ],
                    onChanged: (value) => setState(() => _scope = value!),
                  ),
                  const SizedBox(height: 12),
                  FormFieldView(
                      controller: _description,
                      label: 'Description',
                      maxLines: 3),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Role'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
}
