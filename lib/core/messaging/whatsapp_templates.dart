const whatsappOrderReceivedStorageKey = 'whatsapp_order_received_template';
const whatsappOrderInProgressStorageKey = 'whatsapp_order_in_progress_template';
const whatsappOrderReadyStorageKey = 'whatsapp_order_ready_template';

const _legacyOrderReceivedWhatsAppTemplate = '''
Namaste, Mr. {{1}}

Your dress stitching order is with us, and the expected delivery date is {{2}}.

We will notify you once the dress stitching order is complete.

Thank you!''';

const _legacyOrderReadyWhatsAppTemplate = '''
Namaste, Mr. {{1}}

Great news! Your dress stitching orders are now complete and ready for pickup.

Bill Summary:
Total Bill Amount: Rs {{2}}
Paid Amount: Rs {{3}}
Balance Due: Rs {{4}}

Please visit our shop to collect your items.

Thank you!''';

const defaultOrderReceivedWhatsAppTemplate = '''
नमस्कार {{1}},

आपली शिवणकामाची ऑर्डर आम्हाला मिळाली आहे.
ऑर्डर पूर्ण होण्याची अपेक्षित तारीख: {{2}}

काम सुरू झाल्यावर आणि ऑर्डर पूर्ण झाल्यावर आम्ही आपल्याला कळवू.

धन्यवाद!''';

const defaultOrderInProgressWhatsAppTemplate = '''
नमस्कार {{1}},

आपल्या ऑर्डरमधील {{2}} चे शिवणकाम सुरू झाले आहे.
ऑर्डर पूर्ण झाल्यावर आम्ही आपल्याला कळवू.

धन्यवाद!''';

const defaultOrderReadyWhatsAppTemplate = '''
नमस्कार {{1}},

आपली शिवणकामाची ऑर्डर पूर्ण झाली आहे आणि घेऊन जाण्यासाठी तयार आहे.

बिल तपशील:
एकूण रक्कम: रु. {{2}}
भरलेली रक्कम: रु. {{3}}
बाकी रक्कम: रु. {{4}}

कृपया आपली ऑर्डर घेण्यासाठी दुकानात या.

धन्यवाद!''';

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

Uri buildManualWhatsAppUri({
  required String phone,
  required String message,
}) {
  final normalizedPhone = normalizeWhatsAppPhoneNumber(phone);
  return Uri.https(
    'wa.me',
    '/$normalizedPhone',
    {'text': message},
  );
}

String? migrateLegacyWhatsAppTemplate(String key, String? savedTemplate) {
  if (savedTemplate == null || savedTemplate.trim().isEmpty) return null;
  final template = savedTemplate.trim();
  if (key == whatsappOrderReceivedStorageKey &&
      template == _legacyOrderReceivedWhatsAppTemplate.trim()) {
    return defaultOrderReceivedWhatsAppTemplate;
  }
  if (key == whatsappOrderReadyStorageKey &&
      template == _legacyOrderReadyWhatsAppTemplate.trim()) {
    return defaultOrderReadyWhatsAppTemplate;
  }
  return savedTemplate;
}
