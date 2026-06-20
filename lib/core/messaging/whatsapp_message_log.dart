enum WhatsAppMessageType {
  order,
  delivery,
  reminder;

  String get label => switch (this) {
        order => 'Order',
        delivery => 'Delivery',
        reminder => 'In Progress',
      };
}

enum WhatsAppMessageStatus {
  success,
  failure,
  hold;

  String get label => switch (this) {
        success => 'Success',
        failure => 'Failure',
        hold => 'Hold',
      };
}

class WhatsAppMessageLog {
  const WhatsAppMessageLog({
    required this.id,
    required this.eventKey,
    required this.orderId,
    required this.customerName,
    required this.phone,
    required this.messageType,
    required this.status,
    required this.messageTemplate,
    required this.renderedMessage,
    required this.createdAt,
    required this.updatedAt,
    this.providerMessageId,
    this.errorMessage,
  });

  final String id;
  final String eventKey;
  final String orderId;
  final String customerName;
  final String phone;
  final WhatsAppMessageType messageType;
  final WhatsAppMessageStatus status;
  final String messageTemplate;
  final String renderedMessage;
  final String? providerMessageId;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
}

abstract interface class WhatsAppMessageLogStore {
  Future<bool> eventExists(String eventKey);

  Future<bool> insert(WhatsAppMessageLog log);

  Future<void> updateResult({
    required String eventKey,
    required WhatsAppMessageStatus status,
    String? providerMessageId,
    String? errorMessage,
  });

  Future<List<WhatsAppMessageLog>> list({int limit = 250});
}
