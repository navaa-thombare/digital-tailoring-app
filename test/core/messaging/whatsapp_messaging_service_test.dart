import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:storemanagement/core/messaging/whatsapp_api_config.dart';
import 'package:storemanagement/core/messaging/whatsapp_message_log.dart';
import 'package:storemanagement/core/messaging/whatsapp_messaging_service.dart';

void main() {
  const configured = WhatsAppApiConfig(
    enabled: true,
    apiVersion: 'v23.0',
    phoneNumberId: '12345',
    accessToken: 'secret-token',
    senderName: 'Digital Tailoring',
  );

  test('Meta gateway sends normalized phone and returns provider message id',
      () async {
    late http.Request captured;
    final gateway = MetaWhatsAppCloudGateway(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'messages': [
              {'id': 'wamid.123'},
            ],
          }),
          200,
        );
      }),
    );

    final result = await gateway.send(
      config: configured,
      phone: '98765 43210',
      message: 'Order ready',
    );

    expect(result.status, WhatsAppMessageStatus.success);
    expect(result.providerMessageId, 'wamid.123');
    expect(
      captured.url.toString(),
      'https://graph.facebook.com/v23.0/12345/messages',
    );
    expect(captured.headers['authorization'], 'Bearer secret-token');
    expect(jsonDecode(captured.body)['to'], '919876543210');
  });

  test('unconfigured automatic message is logged once as hold', () async {
    final logs = _FakeMessageLogStore();
    final gateway = _FakeGateway();
    final service = WhatsAppMessagingService(
      repository: logs,
      gateway: gateway,
      configReader: () async => const WhatsAppApiConfig(
        enabled: false,
        apiVersion: 'v23.0',
        phoneNumberId: '',
        accessToken: '',
        senderName: '',
      ),
      templateReader: (_) async => null,
    );

    await service.sendOrderCreated(
      orderId: 'ORD-1',
      customerName: 'A',
      phone: '9876543210',
      deliveryDate: '20/Jun/2026',
    );
    await service.sendOrderCreated(
      orderId: 'ORD-1',
      customerName: 'A',
      phone: '9876543210',
      deliveryDate: '20/Jun/2026',
    );

    expect(logs.logs, hasLength(1));
    expect(logs.logs.single.status, WhatsAppMessageStatus.hold);
    expect(logs.logs.single.messageType, WhatsAppMessageType.order);
    expect(gateway.sendCount, 0);
  });

  test('configured ready message updates history to provider result', () async {
    final logs = _FakeMessageLogStore();
    final gateway = _FakeGateway(
      result: const WhatsAppSendResult(
        status: WhatsAppMessageStatus.success,
        providerMessageId: 'wamid.ready',
      ),
    );
    final service = WhatsAppMessagingService(
      repository: logs,
      gateway: gateway,
      configReader: () async => configured,
      templateReader: (_) async => null,
    );

    await service.sendOrderReady(
      orderId: 'ORD-2',
      customerName: 'A',
      phone: '9876543210',
      totalAmount: 2000,
      paidAmount: 500,
      balanceAmount: 1500,
    );

    expect(gateway.sendCount, 1);
    expect(logs.logs.single.status, WhatsAppMessageStatus.success);
    expect(logs.logs.single.providerMessageId, 'wamid.ready');
    expect(logs.logs.single.messageType, WhatsAppMessageType.delivery);
  });
}

class _FakeGateway implements WhatsAppMessageGateway {
  _FakeGateway({
    this.result = const WhatsAppSendResult(
      status: WhatsAppMessageStatus.success,
    ),
  });

  final WhatsAppSendResult result;
  int sendCount = 0;

  @override
  Future<WhatsAppSendResult> send({
    required WhatsAppApiConfig config,
    required String phone,
    required String message,
  }) async {
    sendCount++;
    return result;
  }
}

class _FakeMessageLogStore implements WhatsAppMessageLogStore {
  final List<WhatsAppMessageLog> logs = [];

  @override
  Future<bool> eventExists(String eventKey) async {
    return logs.any((log) => log.eventKey == eventKey);
  }

  @override
  Future<bool> insert(WhatsAppMessageLog log) async {
    if (await eventExists(log.eventKey)) return false;
    logs.add(log);
    return true;
  }

  @override
  Future<List<WhatsAppMessageLog>> list({int limit = 250}) async {
    return logs.take(limit).toList();
  }

  @override
  Future<void> updateResult({
    required String eventKey,
    required WhatsAppMessageStatus status,
    String? providerMessageId,
    String? errorMessage,
  }) async {
    final index = logs.indexWhere((log) => log.eventKey == eventKey);
    final current = logs[index];
    logs[index] = WhatsAppMessageLog(
      id: current.id,
      eventKey: current.eventKey,
      orderId: current.orderId,
      customerName: current.customerName,
      phone: current.phone,
      messageType: current.messageType,
      status: status,
      messageTemplate: current.messageTemplate,
      renderedMessage: current.renderedMessage,
      providerMessageId: providerMessageId,
      errorMessage: errorMessage,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
