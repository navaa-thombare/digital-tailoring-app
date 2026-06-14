import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../dao/database_dao.dart';

class TailoringStateSnapshot {
  const TailoringStateSnapshot({
    required this.payload,
    required this.revision,
  });

  final Map<String, dynamic> payload;
  final int revision;
}

class TailoringStateRepository extends DatabaseDao {
  TailoringStateRepository({SupabaseClient? supabase})
      : _supabase = supabase ??
            (AppConfig.hasSupabaseConfig ? Supabase.instance.client : null);

  static const _cacheId = 'active-shop';
  final SupabaseClient? _supabase;
  RealtimeChannel? _channel;
  String? _shopId;
  int _revision = 0;
  bool _saving = false;
  Map<String, dynamic>? _pendingPayload;

  bool get cloudConnected => _shopId != null;

  Future<TailoringStateSnapshot?> loadLocal() async {
    final database = await db;
    final rows = await database.query(
      'tailoring_state_cache',
      where: 'id = ?',
      whereArgs: const [_cacheId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TailoringStateSnapshot(
      payload:
          jsonDecode(rows.first['payload']! as String) as Map<String, dynamic>,
      revision: rows.first['revision']! as int,
    );
  }

  Future<void> saveLocal(Map<String, dynamic> payload, int revision) async {
    final database = await db;
    await database.insert(
      'tailoring_state_cache',
      {
        'id': _cacheId,
        'payload': jsonEncode(payload),
        'revision': revision,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearLocal() async {
    await _waitForSaves();
    final database = await db;
    await database.delete(
      'tailoring_state_cache',
      where: 'id = ?',
      whereArgs: const [_cacheId],
    );
    _revision = 0;
    _pendingPayload = null;
  }

  Future<void> clearCloudShopData() async {
    await _waitForSaves();
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw const AuthException(
        'Sign in to Supabase before clearing cloud data.',
      );
    }
    await client.rpc('clear_my_shop_data');
    _revision = 0;
  }

  Future<void> _waitForSaves() async {
    while (_saving) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    _pendingPayload = null;
  }

  Future<TailoringStateSnapshot> connectOwner({
    required String phone,
    required String password,
    required String ownerName,
    required String shopName,
    required String address,
    required int maxOrdersPerDay,
    required Map<String, dynamic> initialPayload,
    required void Function(TailoringStateSnapshot snapshot) onRemoteChange,
    bool allowSignUp = false,
  }) async {
    final client = _supabase;
    if (client == null) {
      throw const AuthException(
          'Supabase production configuration is missing.');
    }
    final email = _ownerEmail(phone);
    AuthResponse response;
    try {
      response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException {
      if (!allowSignUp) rethrow;
      response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': ownerName, 'mobile': phone},
      );
    }
    final user = response.user ?? client.auth.currentUser;
    final session = response.session ?? client.auth.currentSession;
    if (user == null || session == null) {
      throw const AuthException(
        'Supabase account requires confirmation. Disable email confirmation '
        'for this private owner login or configure a real OWNER_AUTH_EMAIL.',
      );
    }

    final membership = await client
        .from('shop_memberships')
        .select('shop_id')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();
    if (membership == null) {
      await client.rpc('create_my_shop', params: {
        'p_name': shopName,
        'p_owner_name': ownerName,
        'p_mobile': phone,
        'p_address': address,
        'p_max_orders_per_day': maxOrdersPerDay,
      });
    }
    final activeMembership = await client
        .from('shop_memberships')
        .select('shop_id')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .single();
    _shopId = activeMembership['shop_id']! as String;

    final remote = await client
        .from('tailoring_app_state')
        .select('payload, revision')
        .eq('shop_id', _shopId!)
        .maybeSingle();
    TailoringStateSnapshot snapshot;
    if (remote == null) {
      _revision = 1;
      await client.from('tailoring_app_state').insert({
        'shop_id': _shopId,
        'payload': initialPayload,
        'revision': _revision,
        'updated_by': user.id,
      });
      snapshot = TailoringStateSnapshot(
        payload: initialPayload,
        revision: _revision,
      );
    } else {
      _revision = (remote['revision'] as num).toInt();
      snapshot = TailoringStateSnapshot(
        payload: Map<String, dynamic>.from(remote['payload'] as Map),
        revision: _revision,
      );
    }
    await saveLocal(snapshot.payload, snapshot.revision);
    _subscribe(onRemoteChange);
    return snapshot;
  }

  Future<TailoringStateSnapshot?> connectExisting({
    required void Function(TailoringStateSnapshot snapshot) onRemoteChange,
  }) async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return null;
    final membership = await client
        .from('shop_memberships')
        .select('shop_id')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();
    if (membership == null) return null;
    _shopId = membership['shop_id']! as String;
    final remote = await client
        .from('tailoring_app_state')
        .select('payload, revision')
        .eq('shop_id', _shopId!)
        .maybeSingle();
    if (remote == null) return null;
    _revision = (remote['revision'] as num).toInt();
    final snapshot = TailoringStateSnapshot(
      payload: Map<String, dynamic>.from(remote['payload'] as Map),
      revision: _revision,
    );
    await saveLocal(snapshot.payload, snapshot.revision);
    _subscribe(onRemoteChange);
    return snapshot;
  }

  Future<void> save(Map<String, dynamic> payload) async {
    _pendingPayload = payload;
    if (_saving) return;
    _saving = true;
    try {
      while (_pendingPayload != null) {
        final currentPayload = _pendingPayload!;
        _pendingPayload = null;
        final nextRevision = _revision + 1;
        await saveLocal(currentPayload, nextRevision);
        final client = _supabase;
        final shopId = _shopId;
        final user = client?.auth.currentUser;
        if (client != null && shopId != null && user != null) {
          await client.from('tailoring_app_state').upsert({
            'shop_id': shopId,
            'payload': currentPayload,
            'revision': nextRevision,
            'updated_by': user.id,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        }
        _revision = nextRevision;
      }
    } finally {
      _saving = false;
    }
  }

  Future<void> disconnect() async {
    final client = _supabase;
    final channel = _channel;
    if (client != null && channel != null) {
      await client.removeChannel(channel);
    }
    _channel = null;
    _shopId = null;
    await client?.auth.signOut();
  }

  void _subscribe(
    void Function(TailoringStateSnapshot snapshot) onRemoteChange,
  ) {
    final client = _supabase!;
    final shopId = _shopId!;
    final previous = _channel;
    if (previous != null) unawaited(client.removeChannel(previous));
    _channel = client
        .channel('tailoring-state-$shopId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tailoring_app_state',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'shop_id',
            value: shopId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isEmpty) return;
            final revision = (record['revision'] as num).toInt();
            if (revision <= _revision) return;
            _revision = revision;
            final snapshot = TailoringStateSnapshot(
              payload: Map<String, dynamic>.from(record['payload'] as Map),
              revision: revision,
            );
            unawaited(saveLocal(snapshot.payload, revision));
            onRemoteChange(snapshot);
          },
        )
        .subscribe();
  }

  String _ownerEmail(String phone) {
    if (AppConfig.ownerAuthEmail.trim().isNotEmpty) {
      return AppConfig.ownerAuthEmail.trim();
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return '$digits@owners.digital-tailoring.app';
  }
}
