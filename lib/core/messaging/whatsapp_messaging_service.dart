import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../data/repositories/whatsapp_message_repository.dart';
import 'whatsapp_api_config.dart';
import 'whatsapp_message_log.dart';
import 'whatsapp_templates.dart';

class WhatsAppSendResult {
  const WhatsAppSendResult({
    required this.status,
    this.providerMessageId,
    this.errorMessage,
  });

  final WhatsAppMessageStatus status;
  final String? providerMessageId;
  final String? errorMessage;
}

class WhatsAppDispatchResult {
  const WhatsAppDispatchResult({
    required this.log,
    required this.requiresManualSend,
  });

  final WhatsAppMessageLog log;
  final bool requiresManualSend;
}

abstract interface class WhatsAppMessageGateway {
  Future<WhatsAppSendResult> send({
    required WhatsAppApiConfig config,
    required String phone,
    required String message,
  });
}

class MetaWhatsAppCloudGateway implements WhatsAppMessageGateway {
  MetaWhatsAppCloudGateway({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<WhatsAppSendResult> send({
    required WhatsAppApiConfig config,
    required String phone,
    required String message,
  }) async {
    final normalizedPhone = normalizeWhatsAppPhoneNumber(phone);
    if (normalizedPhone.isEmpty) {
      return const WhatsAppSendResult(
        status: WhatsAppMessageStatus.failure,
        errorMessage: 'Customer mobile number is missing.',
      );
    }

    try {
      final response = await _client
          .post(
            Uri.https(
              'graph.facebook.com',
              '/${config.apiVersion}/${config.phoneNumberId}/messages',
            ),
            headers: {
              'Authorization': 'Bearer ${config.accessToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'messaging_product': 'whatsapp',
              'recipient_type': 'individual',
              'to': normalizedPhone,
              'type': 'text',
              'text': {'preview_url': false, 'body': message},
            }),
          )
          .timeout(const Duration(seconds: 20));
      final body = response.body.isEmpty
          ? const <String, Object?>{}
          : jsonDecode(response.body) as Map<String, Object?>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final messages = body['messages'] as List<Object?>?;
        final first = messages?.firstOrNull as Map<String, Object?>?;
        return WhatsAppSendResult(
          status: WhatsAppMessageStatus.success,
          providerMessageId: first?['id'] as String?,
        );
      }
      final error = body['error'] as Map<String, Object?>?;
      return WhatsAppSendResult(
        status: WhatsAppMessageStatus.failure,
        errorMessage: error?['message'] as String? ??
            'WhatsApp API ${response.statusCode}',
      );
    } catch (error) {
      return WhatsAppSendResult(
        status: WhatsAppMessageStatus.failure,
        errorMessage: error.toString(),
      );
    }
  }
}

class WhatsAppMessagingService {
  WhatsAppMessagingService({
    WhatsAppApiConfigStorage? configStorage,
    WhatsAppMessageLogStore? repository,
    WhatsAppMessageGateway? gateway,
    FlutterSecureStorage? templateStorage,
    Future<WhatsAppApiConfig> Function()? configReader,
    Future<String?> Function(String key)? templateReader,
  })  : _configStorage = configStorage ?? WhatsAppApiConfigStorage(),
        _repository = repository ?? WhatsAppMessageRepository(),
        _gateway = gateway ?? MetaWhatsAppCloudGateway(),
        _templateStorage = templateStorage ?? const FlutterSecureStorage(),
        _configReader = configReader,
        _templateReader = templateReader;

  final WhatsAppApiConfigStorage _configStorage;
  final WhatsAppMessageLogStore _repository;
  final WhatsAppMessageGateway _gateway;
  final FlutterSecureStorage _templateStorage;
  final Future<WhatsAppApiConfig> Function()? _configReader;
  final Future<String?> Function(String key)? _templateReader;

  Future<WhatsAppDispatchResult?> sendOrderCreated({
    required String orderId,
    required String customerName,
    required String phone,
    required String deliveryDate,
  }) {
    return _dispatch(
      eventKey: '$orderId:new-order',
      orderId: orderId,
      customerName: customerName,
      phone: phone,
      type: WhatsAppMessageType.order,
      templateKey: whatsappOrderReceivedStorageKey,
      fallbackTemplate: defaultOrderReceivedWhatsAppTemplate,
      replacements: {
        '{{1}}': customerName,
        '{{2}}': deliveryDate,
      },
    );
  }

  Future<WhatsAppDispatchResult?> sendOrderInProgress({
    required String orderId,
    required String customerName,
    required String phone,
    required String templateName,
  }) {
    return _dispatch(
      eventKey: '$orderId:in-progress',
      orderId: orderId,
      customerName: customerName,
      phone: phone,
      type: WhatsAppMessageType.reminder,
      templateKey: whatsappOrderInProgressStorageKey,
      fallbackTemplate: defaultOrderInProgressWhatsAppTemplate,
      replacements: {
        '{{1}}': customerName,
        '{{2}}': templateName,
      },
    );
  }

  Future<WhatsAppDispatchResult?> sendOrderReady({
    required String orderId,
    required String customerName,
    required String phone,
    required int totalAmount,
    required int paidAmount,
    required int balanceAmount,
  }) {
    return _dispatch(
      eventKey: '$orderId:ready',
      orderId: orderId,
      customerName: customerName,
      phone: phone,
      type: WhatsAppMessageType.delivery,
      templateKey: whatsappOrderReadyStorageKey,
      fallbackTemplate: defaultOrderReadyWhatsAppTemplate,
      replacements: {
        '{{1}}': customerName,
        '{{2}}': totalAmount.toString(),
        '{{3}}': paidAmount.toString(),
        '{{4}}': balanceAmount.toString(),
      },
    );
  }

  Future<WhatsAppSendResult> retry(WhatsAppMessageLog log) async {
    final config = await (_configReader?.call() ?? _configStorage.read());
    if (!config.isConfigured) {
      const result = WhatsAppSendResult(
        status: WhatsAppMessageStatus.hold,
        errorMessage:
            'Automatic sending is disabled or WhatsApp API configuration is incomplete.',
      );
      await _repository.updateResult(
        eventKey: log.eventKey,
        status: result.status,
        errorMessage: result.errorMessage,
      );
      return result;
    }

    final result = await _gateway.send(
      config: config,
      phone: log.phone,
      message: log.renderedMessage,
    );
    await _repository.updateResult(
      eventKey: log.eventKey,
      status: result.status,
      providerMessageId: result.providerMessageId,
      errorMessage: result.errorMessage,
    );
    return result;
  }

  Future<WhatsAppDispatchResult?> _dispatch({
    required String eventKey,
    required String orderId,
    required String customerName,
    required String phone,
    required WhatsAppMessageType type,
    required String templateKey,
    required String fallbackTemplate,
    required Map<String, String> replacements,
  }) async {
    if (await _repository.eventExists(eventKey)) return null;

    final storedTemplate = await (_templateReader?.call(templateKey) ??
        _templateStorage.read(key: templateKey));
    final savedTemplate =
        migrateLegacyWhatsAppTemplate(templateKey, storedTemplate);
    final template = savedTemplate == null || savedTemplate.trim().isEmpty
        ? fallbackTemplate
        : savedTemplate;
    final renderedMessage = renderWhatsAppTemplate(template, replacements);
    final config = await (_configReader?.call() ?? _configStorage.read());
    final now = DateTime.now();
    final configurationError = config.isConfigured
        ? 'Waiting for WhatsApp provider response.'
        : 'Automatic sending is disabled or WhatsApp API configuration is incomplete.';

    final log = WhatsAppMessageLog(
      id: '${now.microsecondsSinceEpoch}-$eventKey',
      eventKey: eventKey,
      orderId: orderId,
      customerName: customerName,
      phone: phone,
      messageType: type,
      status: WhatsAppMessageStatus.hold,
      messageTemplate: template,
      renderedMessage: renderedMessage,
      errorMessage: configurationError,
      createdAt: now,
      updatedAt: now,
    );
    final inserted = await _repository.insert(log);
    if (!inserted) return null;
    if (!config.isConfigured) {
      return WhatsAppDispatchResult(log: log, requiresManualSend: true);
    }

    final result = await _gateway.send(
      config: config,
      phone: phone,
      message: renderedMessage,
    );
    await _repository.updateResult(
      eventKey: eventKey,
      status: result.status,
      providerMessageId: result.providerMessageId,
      errorMessage: result.errorMessage,
    );
    return WhatsAppDispatchResult(
      log: WhatsAppMessageLog(
        id: log.id,
        eventKey: log.eventKey,
        orderId: log.orderId,
        customerName: log.customerName,
        phone: log.phone,
        messageType: log.messageType,
        status: result.status,
        messageTemplate: log.messageTemplate,
        renderedMessage: log.renderedMessage,
        providerMessageId: result.providerMessageId,
        errorMessage: result.errorMessage,
        createdAt: log.createdAt,
        updatedAt: DateTime.now(),
      ),
      requiresManualSend: result.status != WhatsAppMessageStatus.success,
    );
  }
}
