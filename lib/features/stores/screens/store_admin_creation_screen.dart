import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/controllers/auth_controller.dart';
import '../../../domain/services/app_providers.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/form_field_view.dart';

class StoreAdminCreationScreen extends ConsumerStatefulWidget {
  const StoreAdminCreationScreen({super.key, required this.storeId});

  final String storeId;

  @override
  ConsumerState<StoreAdminCreationScreen> createState() =>
      _StoreAdminCreationScreenState();
}

class _StoreAdminCreationScreenState
    extends ConsumerState<StoreAdminCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _temporaryPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _temporaryPassword.text = 'Temp@123456';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _mobile.dispose();
    _temporaryPassword.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final actor = ref.read(authControllerProvider).value?.userId;
      await ref.read(userRepositoryProvider).createStoreAdmin(
            storeId: widget.storeId,
            fullName: _fullName.text,
            email: _email.text,
            mobile: _mobile.text,
            temporaryPassword: _temporaryPassword.text,
            actorUserId: actor,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Store admin created with temporary password.')),
        );
        _fullName.clear();
        _email.clear();
        _mobile.clear();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Unable to create store admin. Email/mobile must be unique.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Create Store Admin',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppHeader(
            title: 'Store Admin User',
            subtitle:
                'The user is forced to change this temporary password on first login.',
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                FormFieldView(
                    controller: _fullName,
                    label: 'Full Name',
                    validator: _required),
                const SizedBox(height: 12),
                FormFieldView(
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                FormFieldView(
                    controller: _mobile,
                    label: 'Mobile',
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                FormFieldView(
                  controller: _temporaryPassword,
                  label: 'Temporary Password',
                  obscureText: true,
                  validator: (value) => value == null || value.length < 10
                      ? 'Use at least 10 characters'
                      : null,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create Admin'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
}
