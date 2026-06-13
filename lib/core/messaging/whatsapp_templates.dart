const whatsappOrderReceivedStorageKey = 'whatsapp_order_received_template';
const whatsappOrderReadyStorageKey = 'whatsapp_order_ready_template';

const defaultOrderReceivedWhatsAppTemplate = '''
Namaste, Mr. {{1}}

Your dress stitching order is with us, and the expected delivery date is {{2}}.

We will notify you once the dress stitching order is complete.

Thank you!''';

const defaultOrderReadyWhatsAppTemplate = '''
Namaste, Mr. {{1}}

Great news! Your dress stitching orders are now complete and ready for pickup.

Bill Summary:
Total Bill Amount: Rs {{2}}
Paid Amount: Rs {{3}}
Balance Due: Rs {{4}}

Please visit our shop to collect your items.

Thank you!''';

String? validateWhatsAppTemplate(
  String value, {
  required List<String> requiredPlaceholders,
}) {
  if (value.trim().isEmpty) return 'This WhatsApp template is required.';
  final missing = [
    for (final placeholder in requiredPlaceholders)
      if (!value.contains(placeholder)) placeholder,
  ];
  if (missing.isNotEmpty) {
    return 'Missing required placeholders: ${missing.join(', ')}';
  }
  return null;
}

String renderWhatsAppTemplate(
  String template,
  Map<String, String> replacements,
) {
  var rendered = template;
  for (final replacement in replacements.entries) {
    rendered = rendered.replaceAll(replacement.key, replacement.value);
  }
  return rendered;
}

String normalizeWhatsAppPhoneNumber(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) return '91$digits';
  return digits;
}
