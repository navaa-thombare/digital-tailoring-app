import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const whatsappApiEnabledStorageKey = 'whatsapp_api_enabled';
const whatsappApiVersionStorageKey = 'whatsapp_api_version';
const whatsappPhoneNumberIdStorageKey = 'whatsapp_phone_number_id';
const whatsappAccessTokenStorageKey = 'whatsapp_access_token';
const whatsappSenderNameStorageKey = 'whatsapp_sender_name';

class WhatsAppApiConfig {
  const WhatsAppApiConfig({
    required this.enabled,
    required this.apiVersion,
    required this.phoneNumberId,
    required this.accessToken,
    required this.senderName,
  });

  final bool enabled;
  final String apiVersion;
  final String phoneNumberId;
  final String accessToken;
  final String senderName;

  bool get isConfigured =>
      enabled &&
      apiVersion.trim().isNotEmpty &&
      phoneNumberId.trim().isNotEmpty &&
      accessToken.trim().isNotEmpty;
}

class WhatsAppApiConfigStorage {
  WhatsAppApiConfigStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<WhatsAppApiConfig> read() async {
    final values = await Future.wait([
      _storage.read(key: whatsappApiEnabledStorageKey),
      _storage.read(key: whatsappApiVersionStorageKey),
      _storage.read(key: whatsappPhoneNumberIdStorageKey),
      _storage.read(key: whatsappAccessTokenStorageKey),
      _storage.read(key: whatsappSenderNameStorageKey),
    ]);
    return WhatsAppApiConfig(
      enabled: values[0] == 'true',
      apiVersion: values[1]?.trim().isNotEmpty == true ? values[1]! : 'v23.0',
      phoneNumberId: values[2] ?? '',
      accessToken: values[3] ?? '',
      senderName: values[4] ?? '',
    );
  }

  Future<void> write(WhatsAppApiConfig config) {
    return Future.wait([
      _storage.write(
        key: whatsappApiEnabledStorageKey,
        value: config.enabled.toString(),
      ),
      _storage.write(
        key: whatsappApiVersionStorageKey,
        value: config.apiVersion.trim(),
      ),
      _storage.write(
        key: whatsappPhoneNumberIdStorageKey,
        value: config.phoneNumberId.trim(),
      ),
      _storage.write(
        key: whatsappAccessTokenStorageKey,
        value: config.accessToken.trim(),
      ),
      _storage.write(
        key: whatsappSenderNameStorageKey,
        value: config.senderName.trim(),
      ),
    ]);
  }
}
