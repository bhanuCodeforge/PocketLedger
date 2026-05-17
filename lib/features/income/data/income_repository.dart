import 'package:uuid/uuid.dart';
import '../../../core/database/base_repository.dart';
import 'income.dart';

class IncomeRepository extends BaseRepository {
  static const _table = 'income';

  // ── Read operations ─────────────────────────────────────────────────────────

  Future<List<Income>> getAll({
    String? walletId,
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
    if (fromDate != null) {
      conditions.add('income_date >= ?');
      args.add(fromDate);
    }
    if (toDate != null) {
      conditions.add('income_date <= ?');
      args.add(toDate);
    }

    final rows = await database.query(
      _table,
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'income_date DESC',
    );
    return rows.map(Income.fromMap).toList();
  }

  Future<Income?> getById(String id) async {
    final database = await db;
    final rows =
        await database.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Income.fromMap(rows.first);
  }

  Future<List<Income>> getByMonth(int year, int month) async {
    final from = DateTime(year, month, 1).millisecondsSinceEpoch;
    final to = DateTime(year, month + 1, 1)
        .subtract(const Duration(milliseconds: 1))
        .millisecondsSinceEpoch;
    return getAll(fromDate: from, toDate: to);
  }

  Future<List<Income>> search(String query) async {
    final database = await db;
    final term = '%${query.toLowerCase()}%';
    final rows = await database.query(
      _table,
      where: 'LOWER(note) LIKE ? OR LOWER(source) LIKE ?',
      whereArgs: [term, term],
      orderBy: 'income_date DESC',
    );
    return rows.map(Income.fromMap).toList();
  }

  // ── Aggregate helpers ────────────────────────────────────────────────────────

  Future<double> getTotalByDateRange(int fromMs, int toMs) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM $_table '
      'WHERE income_date >= ? AND income_date <= ?',
      [fromMs, toMs],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTodayTotal() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final to = DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;
    return getTotalByDateRange(from, to);
  }

  Future<double> getMonthTotal(int year, int month) async {
    final from = DateTime(year, month, 1).millisecondsSinceEpoch;
    final to = DateTime(year, month + 1, 1)
        .subtract(const Duration(milliseconds: 1))
        .millisecondsSinceEpoch;
    return getTotalByDateRange(from, to);
  }

  // ── Write operations ─────────────────────────────────────────────────────────

  Future<String> create(Income income) async {
    final database = await db;
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(_table, {
      ...income.toMap(),
      'id': id,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<void> update(Income income) async {
    final database = await db;
    await database.update(
      _table,
      {
        ...income.toMap(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<void> delete(String id) async {
    final database = await db;
    await database.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
