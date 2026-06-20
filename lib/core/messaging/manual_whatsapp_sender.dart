import 'package:url_launcher/url_launcher.dart';

import 'whatsapp_templates.dart';

Future<bool> openManualWhatsAppMessage({
  required String phone,
  required String message,
}) {
  final uri = buildManualWhatsAppUri(phone: phone, message: message);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
