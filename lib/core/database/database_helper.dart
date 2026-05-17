import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton SQLite database helper.
/// Opens the DB with WAL journal mode, foreign keys ON, and runs
/// all DDL on first launch. Migrations are handled via PRAGMA user_version.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'pocket_ledger.db';
  static const int _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA journal_mode = WAL');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    _createTables(batch);
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here, keyed by version number.
    // e.g. if (oldVersion < 2) { await db.execute(...); }
  }

  void _createTables(Batch batch) {
    // ── user_profile (singleton, id = 1) ─────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL DEFAULT '',
        currency_code TEXT NOT NULL DEFAULT 'INR',
        currency_symbol TEXT NOT NULL DEFAULT '₹',
        language_code TEXT NOT NULL DEFAULT 'en',
        theme_mode TEXT NOT NULL DEFAULT 'system',
        is_onboarding_complete INTEGER NOT NULL DEFAULT 0,
        default_wallet_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // ── security_settings (singleton, id = 1) ─────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS security_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        pin_hash TEXT,
        recovery_phrase_hash TEXT,
        biometric_enabled INTEGER NOT NULL DEFAULT 0,
        auto_lock_minutes INTEGER NOT NULL DEFAULT 1,
        wrong_attempts INTEGER NOT NULL DEFAULT 0,
        is_locked INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    // ── wallets ───────────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS wallets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'cash',
        opening_balance REAL NOT NULL DEFAULT 0.0,
        color TEXT NOT NULL DEFAULT '#2563EB',
        icon TEXT NOT NULL DEFAULT 'account_balance_wallet',
        is_archived INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // ── folders ───────────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id TEXT REFERENCES folders(id) ON DELETE SET NULL,
        color TEXT NOT NULL DEFAULT '#6B7280',
        icon TEXT NOT NULL DEFAULT 'folder',
        status TEXT NOT NULL DEFAULT 'active',
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // ── expenses ──────────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        wallet_id TEXT NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
        folder_id TEXT REFERENCES folders(id) ON DELETE SET NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        payment_mode TEXT NOT NULL DEFAULT 'cash',
        note TEXT NOT NULL DEFAULT '',
        expense_date INTEGER NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurring_rule_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // ── income ────────────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS income (
        id TEXT PRIMARY KEY,
        wallet_id TEXT NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
        folder_id TEXT REFERENCES folders(id) ON DELETE SET NULL,
        amount REAL NOT NULL,
        source TEXT NOT NULL DEFAULT 'other',
        note TEXT NOT NULL DEFAULT '',
        income_date INTEGER NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurring_rule_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // ── tags ──────────────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE COLLATE NOCASE,
        color TEXT NOT NULL DEFAULT '#6B7280',
        created_at INTEGER NOT NULL
      )
    ''');

    // ── entity_tags ───────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS entity_tags (
        entity_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        tag_id TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
        PRIMARY KEY (entity_id, entity_type, tag_id)
      )
    ''');

    // ── attachments ───────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS attachments (
        id TEXT PRIMARY KEY,
        entity_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        mime_type TEXT NOT NULL DEFAULT 'image/jpeg',
        file_size INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // ── contacts ──────────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        note TEXT NOT NULL DEFAULT '',
        avatar_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // ── loans ─────────────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS loans (
        id TEXT PRIMARY KEY,
        contact_id TEXT REFERENCES contacts(id) ON DELETE SET NULL,
        contact_name TEXT NOT NULL,
        type TEXT NOT NULL,
        principal_amount REAL NOT NULL,
        interest_rate REAL NOT NULL DEFAULT 0.0,
        interest_type TEXT NOT NULL DEFAULT 'none',
        compound_frequency TEXT NOT NULL DEFAULT 'monthly',
        start_date INTEGER NOT NULL,
        due_date INTEGER,
        note TEXT NOT NULL DEFAULT '',
        is_settled INTEGER NOT NULL DEFAULT 0,
        settled_at INTEGER,
        wallet_id TEXT REFERENCES wallets(id) ON DELETE SET NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // ── loan_payments ─────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS loan_payments (
        id TEXT PRIMARY KEY,
        loan_id TEXT NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
        amount REAL NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        payment_date INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // ── groups ────────────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        avatar_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // ── group_members ─────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS group_members (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
        contact_id TEXT REFERENCES contacts(id) ON DELETE SET NULL,
        name TEXT NOT NULL,
        is_self INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // ── group_transactions ────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS group_transactions (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
        paid_by_member_id TEXT NOT NULL REFERENCES group_members(id) ON DELETE CASCADE,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL DEFAULT 'other',
        split_type TEXT NOT NULL DEFAULT 'equal',
        transaction_date INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // ── group_transaction_splits ──────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS group_transaction_splits (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL REFERENCES group_transactions(id) ON DELETE CASCADE,
        member_id TEXT NOT NULL REFERENCES group_members(id) ON DELETE CASCADE,
        amount REAL NOT NULL,
        is_settled INTEGER NOT NULL DEFAULT 0,
        settled_at INTEGER
      )
    ''');

    // ── budgets ───────────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        wallet_id TEXT REFERENCES wallets(id) ON DELETE CASCADE,
        amount REAL NOT NULL,
        period TEXT NOT NULL DEFAULT 'monthly',
        alert_at_percent INTEGER NOT NULL DEFAULT 80,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // ── recurring_rules ───────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS recurring_rules (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        template_data TEXT NOT NULL,
        frequency TEXT NOT NULL,
        interval_value INTEGER NOT NULL DEFAULT 1,
        start_date INTEGER NOT NULL,
        end_date INTEGER,
        next_due_date INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // ── backup_metadata ───────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS backup_metadata (
        id TEXT PRIMARY KEY,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL DEFAULT 0,
        checksum TEXT NOT NULL,
        drive_file_id TEXT,
        backup_type TEXT NOT NULL DEFAULT 'manual',
        created_at INTEGER NOT NULL
      )
    ''');

    // ── sms_import_log ────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS sms_import_log (
        id TEXT PRIMARY KEY,
        sms_address TEXT NOT NULL,
        sms_body_hash TEXT NOT NULL UNIQUE,
        expense_id TEXT,
        import_status TEXT NOT NULL DEFAULT 'imported',
        imported_at INTEGER NOT NULL
      )
    ''');

    // ── ai_insights ───────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ai_insights (
        id TEXT PRIMARY KEY,
        insight_type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        data TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        expires_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // ── change_log (sync) ─────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS change_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // ── conflict_log ──────────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE IF NOT EXISTS conflict_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        local_data TEXT NOT NULL,
        remote_data TEXT NOT NULL,
        resolved INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // ── Indexes ───────────────────────────────────────────────────────────────
    batch.execute('CREATE INDEX IF NOT EXISTS idx_expenses_wallet ON expenses(wallet_id)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_income_wallet ON income(wallet_id)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_income_date ON income(income_date)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_entity_tags_entity ON entity_tags(entity_id, entity_type)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_attachments_entity ON attachments(entity_id, entity_type)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_loans_contact ON loans(contact_id)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_loan_payments_loan ON loan_payments(loan_id)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_budgets_category ON budgets(category)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_change_log_synced ON change_log(synced)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_ai_insights_type ON ai_insights(insight_type, is_read)');
  }

  /// Close the database (for testing / teardown).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
