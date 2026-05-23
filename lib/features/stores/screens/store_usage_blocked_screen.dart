import 'package:flutter/material.dart';

import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_shell.dart';

class StoreUsageBlockedScreen extends StatelessWidget {
  const StoreUsageBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Usage Expired',
      child: Column(
        children: [
          AppHeader(
            title: 'Store Usage Expired',
            subtitle:
                'Store-level modules are blocked until usage is renewed by the shop owner.',
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Ask the shop owner to renew the usage period.'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
