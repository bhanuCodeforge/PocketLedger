import 'package:uuid/uuid.dart';
import '../../../core/database/base_repository.dart';
import 'loan.dart';
import 'loan_payment.dart';

class LoanRepository extends BaseRepository {
  static const _loansTable = 'loans';
  static const _paymentsTable = 'loan_payments';

  Future<List<Loan>> getAll({bool? settled}) async {
    final database = await db;
    String? where;
    List<Object?>? whereArgs;
    if (settled != null) {
      where = 'is_settled = ?';
      whereArgs = [settled ? 1 : 0];
    }
    final rows = await database.query(
      _loansTable,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return rows.map(Loan.fromMap).toList();
  }

  Future<Loan?> getById(String id) async {
    final database = await db;
    final rows = await database
        .query(_loansTable, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Loan.fromMap(rows.first);
  }

  Future<String> create(Loan loan) async {
    final database = await db;
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(_loansTable, {
      ...loan.toMap(),
      'id': id,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<void> update(Loan loan) async {
    final database = await db;
    await database.update(
      _loansTable,
      {...loan.toMap(), 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<void> settle(String id) async {
    final database = await db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.update(
      _loansTable,
      {'is_settled': 1, 'settled_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final database = await db;
    await database.delete(_loansTable, where: 'id = ?', whereArgs: [id]);
  }

  // ── Payments ────────────────────────────────────────────────────────────────

  Future<List<LoanPayment>> getPayments(String loanId) async {
    final database = await db;
    final rows = await database.query(
      _paymentsTable,
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'payment_date DESC',
    );
    return rows.map(LoanPayment.fromMap).toList();
  }

  Future<String> addPayment(LoanPayment payment) async {
    final database = await db;
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(_paymentsTable, {
      ...payment.toMap(),
      'id': id,
      'created_at': now,
    });
    // Also touch the loan's updated_at so providers can detect the change.
    await database.update(
      _loansTable,
      {'updated_at': now},
      where: 'id = ?',
      whereArgs: [payment.loanId],
    );
    return id;
  }

  Future<double> getTotalPaid(String loanId) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COALESCE(SUM(amount), 0.0) AS total FROM $_paymentsTable WHERE loan_id = ?',
      [loanId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
