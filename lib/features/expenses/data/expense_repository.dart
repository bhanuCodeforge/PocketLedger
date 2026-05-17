import 'package:uuid/uuid.dart';
import '../../../core/database/base_repository.dart';
import 'expense.dart';

class ExpenseRepository extends BaseRepository {
  static const _table = 'expenses';

  // ── Queries ──────────────────────────────────────────────────────────────

  Future<List<Expense>> getAll({
    String? walletId,
    String? category,
    int? fromDate,
    int? toDate,
  }) async {
    final database = await db;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (walletId != null) {
      conditions.add('wallet_id = ?');
      args.add(walletId);
    }
    if (category != null) {
      conditions.add('category = ?');
      args.add(category);
    }
    if (fromDate != null) {
      conditions.add('expense_date >= ?');
      args.add(fromDate);
    }
    if (toDate != null) {
      conditions.add('expense_date <= ?');
      args.add(toDate);
    }

    final rows = await database.query(
      _table,
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'expense_date DESC, created_at DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<Expense?> getById(String id) async {
    final database = await db;
    final rows =
        await database.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Expense.fromMap(rows.first);
  }

  // ── Mutations ────────────────────────────────────────────────────────────

  Future<String> create(Expense expense) async {
    final database = await db;
    final id =
        expense.id.isEmpty ? const Uuid().v4() : expense.id;
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(_table, {
      ...expense.toMap(),
      'id': id,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<void> update(Expense expense) async {
    final database = await db;
    await database.update(
      _table,
      {
        ...expense.toMap(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> delete(String id) async {
    final database = await db;
    await database.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // ── Aggregations ─────────────────────────────────────────────────────────

  Future<double> getTotalByDateRange(int fromMs, int toMs) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM $_table '
      'WHERE expense_date >= ? AND expense_date <= ?',
      [fromMs, toMs],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Expense>> getByMonth(int year, int month) async {
    final start = DateTime(year, month).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1)
        .subtract(const Duration(milliseconds: 1))
        .millisecondsSinceEpoch;
    return getAll(fromDate: start, toDate: end);
  }

  Future<double> getTodayTotal() async {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;
    return getTotalByDateRange(startOfDay, endOfDay);
  }

  Future<Map<String, double>> getCategoryTotals(
      int fromMs, int toMs) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT category, COALESCE(SUM(amount), 0) AS total FROM $_table '
      'WHERE expense_date >= ? AND expense_date <= ? '
      'GROUP BY category',
      [fromMs, toMs],
    );
    return {
      for (final row in result)
        row['category'] as String: (row['total'] as num).toDouble(),
    };
  }

  Future<List<Expense>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final database = await db;
    final pattern = '%${query.trim()}%';
    final rows = await database.query(
      _table,
      where: 'note LIKE ? OR category LIKE ?',
      whereArgs: [pattern, pattern],
      orderBy: 'expense_date DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }
}
