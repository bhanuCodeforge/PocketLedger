import 'package:uuid/uuid.dart';
import '../../../core/database/base_repository.dart';
import 'group.dart';

class GroupRepository extends BaseRepository {
  static const _groups = 'groups';
  static const _members = 'group_members';
  static const _transactions = 'group_transactions';
  static const _splits = 'group_transaction_splits';

  // ── Groups ────────────────────────────────────────────────────────────────

  Future<List<SplitGroup>> getGroups() async {
    final database = await db;
    final rows = await database.query(_groups, orderBy: 'created_at DESC');
    return rows.map(SplitGroup.fromMap).toList();
  }

  Future<SplitGroup?> getGroupById(String id) async {
    final database = await db;
    final rows =
        await database.query(_groups, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return SplitGroup.fromMap(rows.first);
  }

  Future<String> createGroup(SplitGroup g) async {
    final database = await db;
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(_groups, {
      ...g.toMap(),
      'id': id,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<void> updateGroup(SplitGroup g) async {
    final database = await db;
    await database.update(
      _groups,
      {...g.toMap(), 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [g.id],
    );
  }

  Future<void> deleteGroup(String id) async {
    final database = await db;
    await database.delete(_groups, where: 'id = ?', whereArgs: [id]);
  }

  // ── Members ───────────────────────────────────────────────────────────────

  Future<List<GroupMember>> getMembers(String groupId) async {
    final database = await db;
    final rows = await database.query(
      _members,
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'is_self DESC, created_at ASC',
    );
    return rows.map(GroupMember.fromMap).toList();
  }

  Future<String> addMember(GroupMember m) async {
    final database = await db;
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(_members, {
      ...m.toMap(),
      'id': id,
      'created_at': now,
    });
    return id;
  }

  Future<void> removeMember(String id) async {
    final database = await db;
    await database.delete(_members, where: 'id = ?', whereArgs: [id]);
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<List<GroupTransaction>> getTransactions(String groupId) async {
    final database = await db;
    final rows = await database.query(
      _transactions,
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'transaction_date DESC, created_at DESC',
    );
    return rows.map(GroupTransaction.fromMap).toList();
  }

  Future<String> createTransaction(GroupTransaction t) async {
    final database = await db;
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(_transactions, {
      ...t.toMap(),
      'id': id,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  // ── Splits ────────────────────────────────────────────────────────────────

  Future<List<GroupTransactionSplit>> getSplits(String transactionId) async {
    final database = await db;
    final rows = await database.query(
      _splits,
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return rows.map(GroupTransactionSplit.fromMap).toList();
  }

  Future<String> createSplit(GroupTransactionSplit s) async {
    final database = await db;
    final id = const Uuid().v4();
    await database.insert(_splits, {...s.toMap(), 'id': id});
    return id;
  }

  Future<void> settleSplit(String splitId) async {
    final database = await db;
    await database.update(
      _splits,
      {
        'is_settled': 1,
        'settled_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [splitId],
    );
  }

  // ── Balance calculation ───────────────────────────────────────────────────

  /// Returns a map of memberId → net balance.
  /// Positive = other members owe this member money.
  /// Negative = this member owes others.
  Future<Map<String, double>> getGroupBalance(String groupId) async {
    final database = await db;

    // Amounts paid by each member (payer gets credit).
    final paidRows = await database.rawQuery(
      '''
      SELECT paid_by_member_id AS member_id,
             COALESCE(SUM(amount), 0) AS paid
      FROM $_transactions
      WHERE group_id = ?
      GROUP BY paid_by_member_id
      ''',
      [groupId],
    );

    // Amounts each member owes across all splits (settled or not).
    final owedRows = await database.rawQuery(
      '''
      SELECT s.member_id,
             COALESCE(SUM(s.amount), 0) AS owed
      FROM $_splits s
      INNER JOIN $_transactions t ON t.id = s.transaction_id
      WHERE t.group_id = ?
      GROUP BY s.member_id
      ''',
      [groupId],
    );

    final Map<String, double> balance = {};

    for (final row in paidRows) {
      final id = row['member_id'] as String;
      balance[id] = (balance[id] ?? 0) + (row['paid'] as num).toDouble();
    }

    for (final row in owedRows) {
      final id = row['member_id'] as String;
      balance[id] = (balance[id] ?? 0) - (row['owed'] as num).toDouble();
    }

    return balance;
  }

  /// Returns all unsettled splits for the given group with member info.
  /// Result: list of {fromMemberId, toMemberId, amount}.
  Future<List<Map<String, dynamic>>> getUnsettledDebts(String groupId) async {
    final database = await db;
    final rows = await database.rawQuery(
      '''
      SELECT s.id AS split_id,
             s.member_id AS debtor_member_id,
             t.paid_by_member_id AS creditor_member_id,
             s.amount
      FROM $_splits s
      INNER JOIN $_transactions t ON t.id = s.transaction_id
      WHERE t.group_id = ?
        AND s.is_settled = 0
        AND s.member_id != t.paid_by_member_id
      ORDER BY s.amount DESC
      ''',
      [groupId],
    );
    return rows.cast<Map<String, dynamic>>();
  }

  /// Total spend for the group (sum of all transaction amounts).
  Future<double> getGroupTotal(String groupId) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM $_transactions WHERE group_id = ?',
      [groupId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
