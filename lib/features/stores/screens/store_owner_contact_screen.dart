import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/app_providers.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/form_field_view.dart';
import '../../../shared/widgets/loading_view.dart';

class StoreOwnerContactScreen extends ConsumerStatefulWidget {
  const StoreOwnerContactScreen({super.key, required this.storeId});

  final String storeId;

  @override
  ConsumerState<StoreOwnerContactScreen> createState() =>
      _StoreOwnerContactScreenState();
}

class _StoreOwnerContactScreenState
    extends ConsumerState<StoreOwnerContactScreen> {
  final _contactEmail = TextEditingController();
  final _contactMobile = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController();
  final _pincode = TextEditingController();
  final _ownerName = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _ownerMobile = TextEditingController();
  final _ownerAltMobile = TextEditingController();
  final _ownerAddress = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    for (final controller in [
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

  Future<void> _load() async {
    if (_loaded) {
      return;
    }
    final repo = ref.read(storeRepositoryProvider);
    final contact = await repo.contact(widget.storeId);
    final owners = await repo.owners(widget.storeId);
    final owner = owners.isNotEmpty ? owners.first : <String, Object?>{};
    _contactEmail.text = '${contact?['email'] ?? ''}';
    _contactMobile.text = '${contact?['mobile'] ?? ''}';
    _address.text = '${contact?['address'] ?? ''}';
    _city.text = '${contact?['city'] ?? ''}';
    _state.text = '${contact?['state'] ?? ''}';
    _country.text = '${contact?['country'] ?? ''}';
    _pincode.text = '${contact?['pincode'] ?? ''}';
    _ownerName.text = '${owner['owner_name'] ?? ''}';
    _ownerEmail.text = '${owner['email'] ?? ''}';
    _ownerMobile.text = '${owner['mobile'] ?? ''}';
    _ownerAltMobile.text = '${owner['alternate_mobile'] ?? ''}';
    _ownerAddress.text = '${owner['address'] ?? ''}';
    _loaded = true;
  }

  Future<void> _save() async {
    await ref.read(storeRepositoryProvider).saveContactAndOwner(
      storeId: widget.storeId,
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner and contact details saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Owner / Contact',
      child: FutureBuilder<void>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AppHeader(title: 'Owner and Contact'),
              FormFieldView(controller: _contactEmail, label: 'Store Email'),
              const SizedBox(height: 12),
              FormFieldView(controller: _contactMobile, label: 'Store Mobile'),
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
              FormFieldView(controller: _pincode, label: 'Pincode'),
              const SizedBox(height: 20),
              Text('Primary Owner',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              FormFieldView(controller: _ownerName, label: 'Owner Name'),
              const SizedBox(height: 12),
              FormFieldView(controller: _ownerEmail, label: 'Owner Email'),
              const SizedBox(height: 12),
              FormFieldView(controller: _ownerMobile, label: 'Owner Mobile'),
              const SizedBox(height: 12),
              FormFieldView(
                  controller: _ownerAltMobile, label: 'Alternate Mobile'),
              const SizedBox(height: 12),
              FormFieldView(
                  controller: _ownerAddress,
                  label: 'Owner Address',
                  maxLines: 2),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
