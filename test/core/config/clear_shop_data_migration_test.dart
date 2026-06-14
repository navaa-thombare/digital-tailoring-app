import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cloud reset migration preserves owner identity and clears shop data',
      () async {
    final migration = await File(
      'supabase/migrations/202606140001_clear_shop_data.sql',
    ).readAsString();

    expect(migration,
        contains('create or replace function public.clear_my_shop_data()'));
    expect(
        migration, contains('where shops.owner_user_id = (select auth.uid())'));
    expect(migration, contains('delete from public.tailoring_app_state'));
    expect(migration, contains('delete from public.orders'));
    expect(migration, contains('delete from public.customers'));
    expect(migration, contains('delete from public.garment_templates'));
    expect(migration, contains('user_id <> (select auth.uid())'));
    expect(migration, isNot(contains('delete from public.shops')));
    expect(migration, isNot(contains('delete from public.profiles')));
  });
}
