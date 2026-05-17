import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pocket_ledger/core/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper', () {
    test('database initializes and all tables exist', () async {
      final db = await DatabaseHelper.instance.database;
      expect(db.isOpen, isTrue);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final tableNames = tables.map((t) => t['name'] as String).toSet();

      const expected = {
        'user_profile',
        'security_settings',
        'wallets',
        'folders',
        'expenses',
        'income',
        'tags',
        'entity_tags',
        'attachments',
        'contacts',
        'loans',
        'loan_payments',
        'groups',
        'group_members',
        'group_transactions',
        'group_transaction_splits',
        'budgets',
        'recurring_rules',
        'backup_metadata',
        'sms_import_log',
        'ai_insights',
        'change_log',
        'conflict_log',
      };

      for (final table in expected) {
        expect(tableNames.contains(table), isTrue,
            reason: 'Table "$table" should exist');
      }
    });

    test('foreign keys are enabled', () async {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.first['foreign_keys'], equals(1));
    });

    test('WAL journal mode is set', () async {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('PRAGMA journal_mode');
      expect(result.first['journal_mode'], equals('wal'));
    });
  });
}
