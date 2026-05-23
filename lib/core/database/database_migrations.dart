class DatabaseMigration {
  const DatabaseMigration({
    required this.version,
    required this.name,
    required this.statements,
  });

  final int version;
  final String name;
  final List<String> statements;
}

class DatabaseMigrations {
  const DatabaseMigrations._();

  static const all = <DatabaseMigration>[
    DatabaseMigration(
      version: 1,
      name: 'create_base_schema',
      statements: [
        '''
        CREATE TABLE roles (
          id TEXT PRIMARY KEY,
          code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          description TEXT,
          scope TEXT NOT NULL CHECK (scope IN ('GLOBAL', 'STORE')),
          is_system_role INTEGER NOT NULL DEFAULT 0 CHECK (is_system_role IN (0, 1)),
          is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
        ''',
        '''
        CREATE TABLE permissions (
          id TEXT PRIMARY KEY,
          code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          description TEXT,
          scope TEXT NOT NULL CHECK (scope IN ('GLOBAL', 'STORE')),
          is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
        ''',
        '''
        CREATE TABLE features (
          id TEXT PRIMARY KEY,
          code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          description TEXT,
          is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
        ''',
        '''
        CREATE TABLE store_types (
          id TEXT PRIMARY KEY,
          code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          description TEXT,
          default_usage_period_days INTEGER NOT NULL DEFAULT 30
            CHECK (default_usage_period_days IN (30, 60, 90, 120, 150, 180)),
          is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
        ''',
        '''
        CREATE TABLE stores (
          id TEXT PRIMARY KEY,
          store_type_id TEXT NOT NULL,
          code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'ACTIVE'
            CHECK (status IN ('ACTIVE', 'INACTIVE', 'EXPIRED')),
          is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
          created_at TEXT NOT NULL,
          updated_at TEXT,
          created_by TEXT,
          updated_by TEXT,
          FOREIGN KEY (store_type_id) REFERENCES store_types(id)
        )
        ''',
        '''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          store_id TEXT,
          username TEXT UNIQUE,
          email TEXT NOT NULL UNIQUE,
          mobile TEXT UNIQUE,
          password_hash TEXT NOT NULL,
          full_name TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
          force_password_change INTEGER NOT NULL DEFAULT 0
            CHECK (force_password_change IN (0, 1)),
          temporary_password INTEGER NOT NULL DEFAULT 0 CHECK (temporary_password IN (0, 1)),
          last_login_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          created_by TEXT,
          updated_by TEXT,
          FOREIGN KEY (store_id) REFERENCES stores(id)
        )
        ''',
        '''
        CREATE TABLE role_permissions (
          id TEXT PRIMARY KEY,
          role_id TEXT NOT NULL,
          permission_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          UNIQUE (role_id, permission_id),
          FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
          FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
        )
        ''',
        '''
        CREATE TABLE user_roles (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          role_id TEXT NOT NULL,
          store_id TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (role_id) REFERENCES roles(id),
          FOREIGN KEY (store_id) REFERENCES stores(id)
        )
        ''',
        '''
        CREATE TABLE store_type_features (
          id TEXT PRIMARY KEY,
          store_type_id TEXT NOT NULL,
          feature_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          UNIQUE (store_type_id, feature_id),
          FOREIGN KEY (store_type_id) REFERENCES store_types(id) ON DELETE CASCADE,
          FOREIGN KEY (feature_id) REFERENCES features(id) ON DELETE CASCADE
        )
        ''',
        '''
        CREATE TABLE store_contacts (
          id TEXT PRIMARY KEY,
          store_id TEXT NOT NULL UNIQUE,
          email TEXT,
          mobile TEXT,
          address TEXT,
          city TEXT,
          state TEXT,
          country TEXT,
          pincode TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
        )
        ''',
        '''
        CREATE TABLE store_owners (
          id TEXT PRIMARY KEY,
          store_id TEXT NOT NULL,
          owner_name TEXT NOT NULL,
          email TEXT,
          mobile TEXT,
          alternate_mobile TEXT,
          address TEXT,
          is_primary_owner INTEGER NOT NULL DEFAULT 1 CHECK (is_primary_owner IN (0, 1)),
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
        )
        ''',
        '''
        CREATE TABLE store_usage_limits (
          id TEXT PRIMARY KEY,
          store_id TEXT NOT NULL,
          usage_period_days INTEGER NOT NULL DEFAULT 30
            CHECK (usage_period_days IN (30, 60, 90, 120, 150, 180)),
          usage_start_date TEXT NOT NULL,
          usage_end_date TEXT NOT NULL,
          remaining_usage_days INTEGER NOT NULL CHECK (remaining_usage_days >= 0),
          last_usage_decrement_date TEXT,
          is_usage_expired INTEGER NOT NULL DEFAULT 0 CHECK (is_usage_expired IN (0, 1)),
          is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
          created_at TEXT NOT NULL,
          updated_at TEXT,
          created_by TEXT,
          updated_by TEXT,
          CHECK (date(usage_end_date) >= date(usage_start_date)),
          FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
        )
        ''',
        '''
        CREATE TABLE audit_logs (
          id TEXT PRIMARY KEY,
          actor_user_id TEXT,
          action_type TEXT NOT NULL,
          entity_type TEXT NOT NULL,
          entity_id TEXT,
          old_value TEXT,
          new_value TEXT,
          remarks TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (actor_user_id) REFERENCES users(id)
        )
        ''',
        '''
        CREATE TABLE login_sessions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          session_token TEXT NOT NULL UNIQUE,
          created_at TEXT NOT NULL,
          expires_at TEXT NOT NULL,
          revoked_at TEXT,
          is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
        ''',
        '''
        CREATE TABLE password_reset_tokens (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          token_hash TEXT NOT NULL UNIQUE,
          expires_at TEXT NOT NULL,
          used_at TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
        ''',
        '''
        CREATE TABLE user_password_history (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          password_hash TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
        ''',
      ],
    ),
    DatabaseMigration(
      version: 2,
      name: 'add_indexes_and_partial_constraints',
      statements: [
        'CREATE INDEX idx_users_store_id ON users(store_id)',
        'CREATE INDEX idx_users_email ON users(email)',
        'CREATE INDEX idx_roles_scope ON roles(scope)',
        'CREATE INDEX idx_permissions_scope ON permissions(scope)',
        "CREATE UNIQUE INDEX idx_user_roles_unique ON user_roles(user_id, role_id, ifnull(store_id, 'GLOBAL'))",
        'CREATE INDEX idx_stores_store_type_id ON stores(store_type_id)',
        'CREATE INDEX idx_stores_status ON stores(status)',
        'CREATE INDEX idx_store_owners_store_id ON store_owners(store_id)',
        'CREATE UNIQUE INDEX idx_store_usage_one_active ON store_usage_limits(store_id) WHERE is_active = 1',
        'CREATE INDEX idx_store_usage_expired ON store_usage_limits(is_usage_expired)',
        'CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at)',
        'CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_user_id)',
        'CREATE INDEX idx_login_sessions_user_id ON login_sessions(user_id)',
      ],
    ),
  ];
}
