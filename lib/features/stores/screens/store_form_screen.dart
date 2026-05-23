import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/services/app_providers.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/form_field_view.dart';
import '../../../shared/widgets/loading_view.dart';

class StoreFormScreen extends ConsumerStatefulWidget {
  const StoreFormScreen({super.key});

  @override
  ConsumerState<StoreFormScreen> createState() => _StoreFormScreenState();
}

class _StoreFormScreenState extends ConsumerState<StoreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _contactEmail = TextEditingController();
  final _contactMobile = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController(text: 'India');
  final _pincode = TextEditingController();
  final _ownerName = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _ownerMobile = TextEditingController();
  final _ownerAltMobile = TextEditingController();
  final _ownerAddress = TextEditingController();
  String? _storeTypeId;
  int _usagePeriod = 30;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _code,
      _name,
      _contactEmail,
      _contactMobile,
      _address,
      _city,
      _state,
      _country,
      _pincode,
      _ownerName,
      _ownerEmail,
      _ownerMobile,
      _ownerAltMobile,
      _ownerAddress,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _storeTypeId == null) return;
    setState(() => _saving = true);
    try {
      final actor = ref.read(authControllerProvider).value?.userId;
      final storeId = await ref.read(storeRepositoryProvider).createStore(
        storeTypeId: _storeTypeId!,
        code: _code.text,
        name: _name.text,
        usagePeriodDays: _usagePeriod,
        actorUserId: actor,
        contact: {
          'email': _contactEmail.text.trim(),
          'mobile': _contactMobile.text.trim(),
          'address': _address.text.trim(),
          'city': _city.text.trim(),
          'state': _state.text.trim(),
          'country': _country.text.trim(),
          'pincode': _pincode.text.trim(),
        },
        owner: {
          'owner_name': _ownerName.text.trim(),
          'email': _ownerEmail.text.trim(),
          'mobile': _ownerMobile.text.trim(),
          'alternate_mobile': _ownerAltMobile.text.trim(),
          'address': _ownerAddress.text.trim(),
        },
      );
      if (mounted) context.go('/stores/$storeId');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Unable to create store. Check unique code and fields.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeTypesFuture =
        ref.watch(storeTypeRepositoryProvider).listStoreTypes();
    return AppShell(
      title: 'Create Store',
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: storeTypesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();
          final types = snapshot.data!;
          _storeTypeId ??=
              types.isNotEmpty ? types.first['id'] as String : null;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const AppHeader(title: 'Create Store'),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _storeTypeId,
                        decoration:
                            const InputDecoration(labelText: 'Store Type'),
                        items: types
                            .map((type) => DropdownMenuItem(
                                  value: type['id'] as String,
                                  child: Text('${type['name']}'),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _storeTypeId = value),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      FormFieldView(
                          controller: _code,
                          label: 'Store Code',
                          validator: _required),
                      const SizedBox(height: 12),
                      FormFieldView(
                          controller: _name,
                          label: 'Store Name',
                          validator: _required),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _usagePeriod,
                        decoration:
                            const InputDecoration(labelText: 'Usage Period'),
                        items: AppConstants.allowedUsagePeriods
                            .map((days) => DropdownMenuItem(
                                value: days, child: Text('$days days')))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _usagePeriod = value!),
                      ),
                      const SizedBox(height: 20),
                      _section(context, 'Contact'),
                      FormFieldView(
                          controller: _contactEmail,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      FormFieldView(
                          controller: _contactMobile,
                          label: 'Mobile',
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      FormFieldView(
                          controller: _address, label: 'Address', maxLines: 2),
                      const SizedBox(height: 12),
                      FormFieldView(controller: _city, label: 'City'),
                      const SizedBox(height: 12),
                      FormFieldView(controller: _state, label: 'State'),
                      const SizedBox(height: 12),
                      FormFieldView(controller: _country, label: 'Country'),
                      const SizedBox(height: 12),
                      FormFieldView(
                          controller: _pincode,
                          label: 'Pincode',
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 20),
                      _section(context, 'Primary Owner'),
                      FormFieldView(
                          controller: _ownerName,
                          label: 'Owner Name',
                          validator: _required),
                      const SizedBox(height: 12),
                      FormFieldView(
                          controller: _ownerEmail, label: 'Owner Email'),
                      const SizedBox(height: 12),
                      FormFieldView(
                          controller: _ownerMobile, label: 'Owner Mobile'),
                      const SizedBox(height: 12),
                      FormFieldView(
                          controller: _ownerAltMobile,
                          label: 'Alternate Mobile'),
                      const SizedBox(height: 12),
                      FormFieldView(
                          controller: _ownerAddress,
                          label: 'Owner Address',
                          maxLines: 2),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save),
                        label: const Text('Create Store'),
                      ),
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

  Widget _section(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
}
