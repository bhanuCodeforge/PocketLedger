import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/base_repository.dart';
import 'insight.dart';

class InsightRepository extends BaseRepository {
  static const _table = 'ai_insights';

  // ── Queries ──────────────────────────────────────────────────────────────

  /// Returns all non-expired insights.
  /// When [unreadOnly] is true, returns only unread rows.
  Future<List<AiInsight>> getAll({bool unreadOnly = false}) async {
    final database = await db;
    final now = DateTime.now().millisecondsSinceEpoch;

    final conditions = <String>['expires_at > ?'];
    final args = <dynamic>[now];

    if (unreadOnly) {
      conditions.add('is_read = 0');
    }

    final rows = await database.query(
      _table,
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'is_read ASC, created_at DESC',
    );
    return rows.map(AiInsight.fromMap).toList();
  }

  /// Returns insights whose [insightType] matches and that have not yet expired.
  Future<List<AiInsight>> getByType(InsightType type) async {
    final database = await db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await database.query(
      _table,
      where: 'insight_type = ? AND expires_at > ?',
      whereArgs: [type.value, now],
      orderBy: 'created_at DESC',
    );
    return rows.map(AiInsight.fromMap).toList();
  }

  // ── Mutations ────────────────────────────────────────────────────────────

  /// Upserts [insight] (insert or replace).  Returns the stored id.
  Future<String> save(AiInsight insight) async {
    final database = await db;
    final id = insight.id.isEmpty ? const Uuid().v4() : insight.id;
    final now = DateTime.now().millisecondsSinceEpoch;

    final map = {
      ...insight.toMap(),
      'id': id,
      'created_at': insight.createdAt == 0 ? now : insight.createdAt,
    };

    await database.insert(
      _table,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  /// Marks the insight with [id] as read.
  Future<void> markRead(String id) async {
    final database = await db;
    await database.update(
      _table,
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all insights whose [expires_at] is in the past.
  Future<void> deleteExpired() async {
    final database = await db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.delete(
      _table,
      where: 'expires_at < ?',
      whereArgs: [now],
    );
  }

  /// Removes every row from [ai_insights].
  Future<void> clearAll() async {
    final database = await db;
    await database.delete(_table);
  }
}
