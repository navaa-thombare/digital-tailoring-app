import 'package:flutter_test/flutter_test.dart';
import 'package:storemanagement/core/messaging/whatsapp_templates.dart';

void main() {
  test('default order received template contains mandatory placeholders', () {
    expect(
      validateWhatsAppTemplate(
        defaultOrderReceivedWhatsAppTemplate,
        requiredPlaceholders: const ['{{1}}', '{{2}}'],
      ),
      isNull,
    );
  });

  test('default ready template contains all bill placeholders', () {
    expect(
      validateWhatsAppTemplate(
        defaultOrderReadyWhatsAppTemplate,
        requiredPlaceholders: const ['{{1}}', '{{2}}', '{{3}}', '{{4}}'],
      ),
      isNull,
    );
  });

  test('default in-progress template is Marathi and keeps placeholders', () {
    expect(
      validateWhatsAppTemplate(
        defaultOrderInProgressWhatsAppTemplate,
        requiredPlaceholders: const ['{{1}}', '{{2}}'],
      ),
      isNull,
    );
    expect(defaultOrderInProgressWhatsAppTemplate, contains('शिवणकाम सुरू'));
  });

  test('validation reports missing placeholders', () {
    expect(
      validateWhatsAppTemplate(
        'Hello {{1}}',
        requiredPlaceholders: const ['{{1}}', '{{2}}'],
      ),
      contains('{{2}}'),
    );
  });

  test('renders placeholders with customer and order values', () {
    expect(
      renderWhatsAppTemplate(
        'Hello {{1}}, delivery {{2}}',
        const {'{{1}}': 'Aarav', '{{2}}': '20 Jun'},
      ),
      'Hello Aarav, delivery 20 Jun',
    );
  });

  test('adds India country code to a local mobile number', () {
    expect(normalizeWhatsAppPhoneNumber('98765 43210'), '919876543210');
  });

  test('builds a manual WhatsApp link with Marathi message', () {
    final uri = buildManualWhatsAppUri(
      phone: '98765 43210',
      message: 'आपली ऑर्डर तयार आहे.',
    );

    expect(uri.host, 'wa.me');
    expect(uri.path, '/919876543210');
    expect(uri.queryParameters['text'], 'आपली ऑर्डर तयार आहे.');
  });

  test('migrates only the old stock English templates to Marathi', () {
    const oldOrderTemplate = '''
Namaste, Mr. {{1}}

Your dress stitching order is with us, and the expected delivery date is {{2}}.

We will notify you once the dress stitching order is complete.

Thank you!''';

    expect(
      migrateLegacyWhatsAppTemplate(
        whatsappOrderReceivedStorageKey,
        oldOrderTemplate,
      ),
      defaultOrderReceivedWhatsAppTemplate,
    );
    expect(
      migrateLegacyWhatsAppTemplate(
        whatsappOrderReceivedStorageKey,
        'My custom {{1}} {{2}}',
      ),
      'My custom {{1}} {{2}}',
    );
  });
}
