import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storemanagement/core/messaging/whatsapp_api_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clear removes every saved WhatsApp API setting', () async {
    FlutterSecureStorage.setMockInitialValues({
      whatsappApiEnabledStorageKey: 'true',
      whatsappApiVersionStorageKey: 'v23.0',
      whatsappPhoneNumberIdStorageKey: '12345',
      whatsappAccessTokenStorageKey: 'secret',
      whatsappSenderNameStorageKey: 'Digital Tailoring',
      'unrelated': 'preserved',
    });
    final storage = WhatsAppApiConfigStorage();

    await storage.clear();

    final config = await storage.read();
    const secureStorage = FlutterSecureStorage();
    expect(config.enabled, isFalse);
    expect(config.apiVersion, 'v23.0');
    expect(config.phoneNumberId, isEmpty);
    expect(config.accessToken, isEmpty);
    expect(config.senderName, isEmpty);
    expect(await secureStorage.read(key: 'unrelated'), 'preserved');
  });
}
