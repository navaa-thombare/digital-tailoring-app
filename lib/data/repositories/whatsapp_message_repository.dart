import 'package:sqflite/sqflite.dart';

import '../../core/messaging/whatsapp_message_log.dart';
import '../dao/database_dao.dart';

class WhatsAppMessageRepository extends DatabaseDao
    implements WhatsAppMessageLogStore {
  @override
  Future<bool> eventExists(String eventKey) async {
    final database = await db;
    final rows = await database.query(
      'whatsapp_message_logs',
      columns: const ['id'],
      where: 'event_key = ?',
      whereArgs: [eventKey],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<bool> insert(WhatsAppMessageLog log) async {
    final database = await db;
    final rowId = await database.insert(
      'whatsapp_message_logs',
      _toMap(log),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return rowId > 0;
  }

  @override
  Future<void> updateResult({
    required String eventKey,
    required WhatsAppMessageStatus status,
    String? providerMessageId,
    String? errorMessage,
  }) async {
    final database = await db;
    await database.update(
      'whatsapp_message_logs',
      {
        'status': status.name,
        'provider_message_id': providerMessageId,
        'error_message': errorMessage,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'event_key = ?',
      whereArgs: [eventKey],
    );
  }

  @override
  Future<List<WhatsAppMessageLog>> list({int limit = 250}) async {
    final database = await db;
    final rows = await database.query(
      'whatsapp_message_logs',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_fromMap).toList(growable: false);
  }

  Map<String, Object?> _toMap(WhatsAppMessageLog log) {
    return {
      'id': log.id,
      'event_key': log.eventKey,
      'order_id': log.orderId,
      'customer_name': log.customerName,
      'phone': log.phone,
      'message_type': log.messageType.name,
      'status': log.status.name,
      'message_template': log.messageTemplate,
      'rendered_message': log.renderedMessage,
      'provider_message_id': log.providerMessageId,
      'error_message': log.errorMessage,
      'created_at': log.createdAt.toUtc().toIso8601String(),
      'updated_at': log.updatedAt.toUtc().toIso8601String(),
    };
  }

  WhatsAppMessageLog _fromMap(Map<String, Object?> row) {
    return WhatsAppMessageLog(
      id: row['id']! as String,
      eventKey: row['event_key']! as String,
      orderId: row['order_id']! as String,
      customerName: row['customer_name']! as String,
      phone: row['phone']! as String,
      messageType: WhatsAppMessageType.values.byName(
        row['message_type']! as String,
      ),
      status: WhatsAppMessageStatus.values.byName(row['status']! as String),
      messageTemplate: row['message_template']! as String,
      renderedMessage: row['rendered_message']! as String,
      providerMessageId: row['provider_message_id'] as String?,
      errorMessage: row['error_message'] as String?,
      createdAt: DateTime.parse(row['created_at']! as String).toLocal(),
      updatedAt: DateTime.parse(row['updated_at']! as String).toLocal(),
    );
  }
}
