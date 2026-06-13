import 'package:flutter_test/flutter_test.dart';
import 'package:storemanagement/core/config/production_seed_migration.dart';

void main() {
  test('production migration removes only legacy demo records', () {
    final payload = <String, dynamic>{
      'schema': 1,
      'customers': [
        {'name': 'Aarav Mehta', 'phone': '9876543410'},
        {'name': 'Nana', 'phone': '9000000000'},
      ],
      'orders': [
        {'id': 'ORD-1042'},
        {'id': 'ORD-49953'},
      ],
      'templates': [
        {'name': 'Men Shirt'},
        {'name': 'Blazer'},
      ],
      'workers': [
        {'mobile': '9876501111'},
        {'mobile': '9000000001'},
      ],
    };

    final migrated = migrateLegacyProductionSeed(
      payload,
      isProduction: true,
    );

    expect(migrated['schema'], currentTailoringStateSchema);
    expect(
      migrated['customers'],
      [
        {'name': 'Nana', 'phone': '9000000000'},
      ],
    );
    expect(
      migrated['orders'],
      [
        {'id': 'ORD-49953'},
      ],
    );
    expect(
      migrated['templates'],
      [
        {'name': 'Blazer'},
      ],
    );
    expect(
      migrated['workers'],
      [
        {'mobile': '9000000001'},
      ],
    );
  });

  test('current production snapshots are not filtered again', () {
    final payload = <String, dynamic>{
      'schema': currentTailoringStateSchema,
      'customers': [
        {'name': 'Real customer', 'phone': '9876543410'},
      ],
      'orders': const [],
      'templates': const [],
      'workers': const [],
    };

    expect(
      identical(
        migrateLegacyProductionSeed(payload, isProduction: true),
        payload,
      ),
      isTrue,
    );
  });
}
