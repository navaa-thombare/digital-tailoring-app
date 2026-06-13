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
}
