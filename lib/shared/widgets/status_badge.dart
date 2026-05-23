import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.active = true});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      backgroundColor: active ? scheme.primaryContainer : scheme.errorContainer,
      labelStyle: TextStyle(
        color: active ? scheme.onPrimaryContainer : scheme.onErrorContainer,
      ),
    );
  }
}
