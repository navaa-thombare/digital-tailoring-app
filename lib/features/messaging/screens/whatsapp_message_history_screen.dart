import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/messaging/whatsapp_message_log.dart';
import '../../../core/messaging/whatsapp_messaging_service.dart';
import '../../../data/repositories/whatsapp_message_repository.dart';

class WhatsAppMessageHistoryScreen extends StatefulWidget {
  const WhatsAppMessageHistoryScreen({super.key});

  @override
  State<WhatsAppMessageHistoryScreen> createState() =>
      _WhatsAppMessageHistoryScreenState();
}

class _WhatsAppMessageHistoryScreenState
    extends State<WhatsAppMessageHistoryScreen> {
  final _repository = WhatsAppMessageRepository();
  final _messagingService = WhatsAppMessagingService();
  late Future<List<WhatsAppMessageLog>> _logs;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Message History'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<WhatsAppMessageLog>>(
          future: _logs,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child:
                      Text('Could not load message history: ${snapshot.error}'),
                ),
              );
            }
            final logs = snapshot.data ?? const [];
            if (logs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No WhatsApp messages recorded yet.\n'
                    'New-order and ready messages will appear here.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('Customer')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Message template')),
                        ],
                        rows: [
                          for (final log in logs)
                            DataRow(
                              onSelectChanged: (_) => _showDetails(log),
                              cells: [
                                DataCell(Text(log.customerName)),
                                DataCell(
                                  Text(DateFormat('dd-MMM-yyyy').format(
                                    log.createdAt,
                                  )),
                                ),
                                DataCell(Text(log.messageType.label)),
                                DataCell(_StatusBadge(status: log.status)),
                                DataCell(
                                  SizedBox(
                                    width: 280,
                                    child: Text(
                                      log.messageTemplate,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _reload() {
    setState(() {
      _logs = _repository.list();
    });
  }

  Future<void> _refresh() async {
    final future = _repository.list();
    setState(() {
      _logs = future;
    });
    await future;
  }

  void _showDetails(WhatsAppMessageLog log) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${log.customerName} - ${log.messageType.label}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Order: ${log.orderId}'),
              Text('Phone: ${log.phone}'),
              Text('Status: ${log.status.label}'),
              Text(
                'Date: ${DateFormat('dd-MMM-yyyy HH:mm').format(log.createdAt)}',
              ),
              if (log.providerMessageId?.isNotEmpty == true)
                Text('Provider ID: ${log.providerMessageId}'),
              if (log.errorMessage?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  log.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Rendered message',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              SelectableText(log.renderedMessage),
              const SizedBox(height: 16),
              const Text(
                'Saved template',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              SelectableText(log.messageTemplate),
            ],
          ),
        ),
        actions: [
          if (log.status != WhatsAppMessageStatus.success)
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final result = await _messagingService.retry(log);
                if (!mounted) return;
                await _refresh();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.status == WhatsAppMessageStatus.success
                          ? 'WhatsApp message sent successfully.'
                          : result.errorMessage ?? 'WhatsApp message not sent.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final WhatsAppMessageStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      WhatsAppMessageStatus.success => (
          const Color(0xFFE1F6E8),
          const Color(0xFF147A3C),
        ),
      WhatsAppMessageStatus.failure => (
          const Color(0xFFFFE4E4),
          const Color(0xFFB42318),
        ),
      WhatsAppMessageStatus.hold => (
          const Color(0xFFFFF1CC),
          const Color(0xFF8A5A00),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: colors.$2, fontWeight: FontWeight.w800),
      ),
    );
  }
}
