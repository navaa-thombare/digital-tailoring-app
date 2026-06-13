import 'package:flutter/material.dart';

import '../../../core/messaging/whatsapp_api_config.dart';

class WhatsAppApiSettingsScreen extends StatefulWidget {
  const WhatsAppApiSettingsScreen({super.key});

  @override
  State<WhatsAppApiSettingsScreen> createState() =>
      _WhatsAppApiSettingsScreenState();
}

class _WhatsAppApiSettingsScreenState extends State<WhatsAppApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiVersion = TextEditingController(text: 'v23.0');
  final _phoneNumberId = TextEditingController();
  final _accessToken = TextEditingController();
  final _senderName = TextEditingController();
  final _storage = WhatsAppApiConfigStorage();
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;
  bool _showToken = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _apiVersion.dispose();
    _phoneNumberId.dispose();
    _accessToken.dispose();
    _senderName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp API Configuration')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Card(
                      color: Color(0xFFEAF3FF),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Automatic sending uses Meta WhatsApp Cloud API. '
                          'Credentials are stored in Android secure storage. '
                          'For production, use a backend so the access token is '
                          'not distributed inside the mobile app.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _enabled,
                      title: const Text(
                        'Enable automatic WhatsApp messages',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: const Text(
                        'Unconfigured or disabled messages are recorded as Hold.',
                      ),
                      onChanged: (value) => setState(() => _enabled = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _apiVersion,
                      decoration: const InputDecoration(
                        labelText: 'Meta Graph API version',
                        hintText: 'v23.0',
                      ),
                      validator: _requiredWhenEnabled,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneNumberId,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp phone number ID',
                      ),
                      validator: _requiredWhenEnabled,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accessToken,
                      obscureText: !_showToken,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Permanent access token',
                        suffixIcon: IconButton(
                          tooltip: _showToken ? 'Hide token' : 'Show token',
                          onPressed: () =>
                              setState(() => _showToken = !_showToken),
                          icon: Icon(
                            _showToken
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: _requiredWhenEnabled,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _senderName,
                      decoration: const InputDecoration(
                        labelText: 'Sender name (optional)',
                        hintText: 'Digital Tailoring Studio',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Card(
                      color: Color(0xFFFFF4D8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Meta may reject free-text business messages outside '
                          'the 24-hour customer service window. Production '
                          'business-initiated messages should use Meta-approved '
                          'WhatsApp templates. Rejections appear as Failure in '
                          'Message History.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving...' : 'Save Configuration'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String? _requiredWhenEnabled(String? value) {
    if (!_enabled) return null;
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  Future<void> _load() async {
    final config = await _storage.read();
    if (!mounted) return;
    _enabled = config.enabled;
    _apiVersion.text = config.apiVersion;
    _phoneNumberId.text = config.phoneNumberId;
    _accessToken.text = config.accessToken;
    _senderName.text = config.senderName;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await _storage.write(
      WhatsAppApiConfig(
        enabled: _enabled,
        apiVersion: _apiVersion.text.trim(),
        phoneNumberId: _phoneNumberId.text.trim(),
        accessToken: _accessToken.text.trim(),
        senderName: _senderName.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WhatsApp API configuration saved.')),
    );
  }
}
