import 'package:uuid/uuid.dart';
import '../../../core/database/base_repository.dart';
import 'budget.dart';

class BudgetRepository extends BaseRepository {
  static const _table = 'budgets';
  static const _expensesTable = 'expenses';

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<List<Budget>> getAll({bool activeOnly = true}) async {
    final database = await db;
    final rows = await database.query(
      _table,
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'created_at DESC',
    );
    return rows.map(Budget.fromMap).toList();
  }

  Future<Budget?> getById(String id) async {
    final database = await db;
    final rows =
        await database.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<String> create(Budget b) async {
    final database = await db;
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(_table, {
      ...b.toMap(),
      'id': id,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<void> update(Budget b) async {
    final database = await db;
    await database.update(
      _table,
      {...b.toMap(), 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [b.id],
    );
  }

  Future<void> delete(String id) async {
    final database = await db;
    await database.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // ── Spent calculation ─────────────────────────────────────────────────────

  /// Queries the expenses table to compute total spending for the budget's
  /// category within the current period window.
  Future<double> getSpentForBudget(Budget b) async {
    final database = await db;
    final now = DateTime.now();

    late final int fromMs;
    late final int toMs;

    switch (b.period) {
      case BudgetPeriod.monthly:
        fromMs = DateTime(now.year, now.month).millisecondsSinceEpoch;
        toMs = DateTime(now.year, now.month + 1)
            .subtract(const Duration(milliseconds: 1))
            .millisecondsSinceEpoch;
        break;
      case BudgetPeriod.weekly:
        // "Last 7 days" rolling window.
        final startOfDay =
            DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
        fromMs = DateTime(now.year, now.month, now.day - 6)
            .millisecondsSinceEpoch;
        toMs = startOfDay +
            const Duration(hours: 23, minutes: 59, seconds: 59)
                .inMilliseconds;
        break;
      case BudgetPeriod.yearly:
        fromMs = DateTime(now.year).millisecondsSinceEpoch;
        toMs = DateTime(now.year + 1)
            .subtract(const Duration(milliseconds: 1))
            .millisecondsSinceEpoch;
        break;
    }

    final conditions = <String>[
      'category = ?',
      'expense_date >= ?',
      'expense_date <= ?',
    ];
    final args = <dynamic>[b.category, fromMs, toMs];

    if (b.walletId != null) {
      conditions.add('wallet_id = ?');
      args.add(b.walletId);
    }

    final result = await database.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total '
      'FROM $_expensesTable '
      'WHERE ${conditions.join(' AND ')}',
      args,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Returns all active budgets enriched with current-period spent amounts.
  Future<List<BudgetWithSpent>> getAllWithSpent() async {
    final budgets = await getAll(activeOnly: true);
    final result = <BudgetWithSpent>[];
    for (final b in budgets) {
      final spent = await getSpentForBudget(b);
      result.add(BudgetWithSpent(budget: b, spentAmount: spent));
    }
    return result;
  }
}
