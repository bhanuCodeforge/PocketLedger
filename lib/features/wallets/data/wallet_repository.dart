import 'package:uuid/uuid.dart';
import '../../../core/database/base_repository.dart';
import 'wallet.dart';

class WalletRepository extends BaseRepository {
  static const _table = 'wallets';

  Future<List<Wallet>> getAllWallets() async {
    final database = await db;
    final rows = await database.query(_table, orderBy: 'created_at ASC');
    return rows.map(Wallet.fromMap).toList();
  }

  Future<List<Wallet>> getActiveWallets() async {
    final database = await db;
    final rows = await database.query(
      _table,
      where: 'is_archived = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
    return rows.map(Wallet.fromMap).toList();
  }

  Future<Wallet?> getWalletById(String id) async {
    final database = await db;
    final rows = await database.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Wallet.fromMap(rows.first);
  }

  Future<String> createWallet(Wallet wallet) async {
    final database = await db;
    final id = wallet.id.isEmpty ? const Uuid().v4() : wallet.id;
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(_table, {
      ...wallet.toMap(),
      'id': id,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<void> updateWallet(Wallet wallet) async {
    final database = await db;
    await database.update(
      _table,
      {...wallet.toMap(), 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<void> archiveWallet(String id) async {
    final database = await db;
    await database.update(
      _table,
      {'is_archived': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> unarchiveWallet(String id) async {
    final database = await db;
    await database.update(
      _table,
      {'is_archived': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getWalletBalance(String id) async {
    final database = await db;
    final result = await database.rawQuery('''
      SELECT
        w.opening_balance
        + COALESCE((SELECT SUM(i.amount) FROM income i WHERE i.wallet_id = w.id), 0)
        - COALESCE((SELECT SUM(e.amount) FROM expenses e WHERE e.wallet_id = w.id), 0)
      AS balance
      FROM wallets w
      WHERE w.id = ?
    ''', [id]);
    if (result.isEmpty) return 0.0;
    return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getActiveWalletCount() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM $_table WHERE is_archived = 0',
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
