import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../utils/app_date_utils.dart';
import '../utils/uuid_utils.dart';

class DatabaseSeed {
  Future<void> seed(Database db) async {
    final now = AppDateUtils.nowIso();
    await db.transaction((txn) async {
      await _seedRoles(txn, now);
      await _seedPermissions(txn, now);
      await _seedRolePermissions(txn, now);
      await _seedFeatures(txn, now);
      await _seedStoreTypes(txn, now);
      await _seedStoreTypeFeatures(txn, now);
    });
  }

  Future<void> _seedRoles(Transaction txn, String now) async {
    final roles = [
      _role('owner', 'Owner', AppConstants.storeScope, true),
      _role('manager', 'Manager', AppConstants.storeScope, true),
      _role('accountant', 'Accountant', AppConstants.storeScope, true),
      _role('worker', 'Worker', AppConstants.storeScope, true),
      _role('inventory', 'Inventory', AppConstants.storeScope, true),
    ];
    for (final role in roles) {
      await txn.insert(
        'roles',
        {...role, 'created_at': now},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _seedPermissions(Transaction txn, String now) async {
    for (final code in _ownerPermissions) {
      await txn.insert(
        'permissions',
        _permission(code, AppConstants.storeScope, now),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    for (final code in _storePermissions) {
      await txn.insert(
        'permissions',
        _permission(code, AppConstants.storeScope, now),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _seedRolePermissions(Transaction txn, String now) async {
    final mappings = <String, List<String>>{
      'owner': _ownerPermissions,
      'manager': [
        'store.dashboard.view',
        'store.users.view',
        'inventory.view',
        'inventory.update',
        'worker.tasks.view',
      ],
      'accountant': ['accounting.view', 'accounting.update'],
      'worker': ['worker.tasks.view', 'worker.tasks.update'],
      'inventory': ['inventory.view', 'inventory.create', 'inventory.update'],
    };

    for (final entry in mappings.entries) {
      final roleId = _id('role', entry.key);
      for (final permissionCode in entry.value) {
        final permissionId = _id('permission', permissionCode);
        await txn.insert(
          'role_permissions',
          {
            'id': _id('role_permission', '${entry.key}:$permissionCode'),
            'role_id': roleId,
            'permission_id': permissionId,
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  Future<void> _seedFeatures(Transaction txn, String now) async {
    const features = [
      'dashboard',
      'user-management',
      'inventory',
      'accounting',
      'worker-tasks',
      'audit-logs',
      'store-usage-management',
    ];
    for (final code in features) {
      await txn.insert(
        'features',
        {
          'id': _id('feature', code),
          'code': code,
          'name': _title(code),
          'description': 'Default feature: ${_title(code)}',
          'is_active': 1,
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _seedStoreTypes(Transaction txn, String now) async {
    const storeTypes = [
      ('tailoring', 'Tailoring'),
      ('garage', 'Garage'),
      ('supershopee', 'Supershopee'),
      ('hotel', 'Hotel'),
    ];
    for (final storeType in storeTypes) {
      await txn.insert(
        'store_types',
        {
          'id': _id('store_type', storeType.$1),
          'code': storeType.$1,
          'name': storeType.$2,
          'description': '${storeType.$2} store type',
          'default_usage_period_days': 30,
          'is_active': 1,
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _seedStoreTypeFeatures(Transaction txn, String now) async {
    const storeTypes = ['tailoring', 'garage', 'supershopee', 'hotel'];
    const features = [
      'dashboard',
      'user-management',
      'inventory',
      'accounting',
      'worker-tasks',
      'audit-logs',
      'store-usage-management',
    ];
    for (final storeType in storeTypes) {
      for (final feature in features) {
        await txn.insert(
          'store_type_features',
          {
            'id': _id('store_type_feature', '$storeType:$feature'),
            'store_type_id': _id('store_type', storeType),
            'feature_id': _id('feature', feature),
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  Map<String, Object?> _role(
    String code,
    String name,
    String scope,
    bool system,
  ) {
    return {
      'id': _id('role', code),
      'code': code,
      'name': name,
      'description': '$name role',
      'scope': scope,
      'is_system_role': system ? 1 : 0,
      'is_active': 1,
    };
  }

  Map<String, Object?> _permission(String code, String scope, String now) {
    return {
      'id': _id('permission', code),
      'code': code,
      'name': _title(code),
      'description': 'Allows ${_title(code)}',
      'scope': scope,
      'is_active': 1,
      'created_at': now,
    };
  }

  static String _id(String namespace, String code) =>
      UuidUtils.stable(namespace, code);

  static String _title(String code) {
    return code
        .replaceAll('.', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static const _ownerPermissions = [
    'store.dashboard.view',
    'store.users.view',
    'store.users.create',
    'store.users.update',
    'roles.view',
    'roles.create',
    'roles.update',
    'roles.activate',
    'roles.deactivate',
    'permissions.view',
    'permissions.create',
    'permissions.update',
    'features.view',
    'features.create',
    'features.update',
    'features.activate',
    'features.deactivate',
    'store_types.view',
    'store_types.create',
    'store_types.update',
    'store_types.activate',
    'store_types.deactivate',
    'stores.view',
    'stores.create',
    'stores.update',
    'stores.activate',
    'stores.deactivate',
    'store_usage_limits.manage',
    'audit_logs.view',
  ];

  static const _storePermissions = [
    'store.dashboard.view',
    'store.users.view',
    'store.users.create',
    'store.users.update',
    'inventory.view',
    'inventory.create',
    'inventory.update',
    'accounting.view',
    'accounting.update',
    'worker.tasks.view',
    'worker.tasks.update',
  ];
}
