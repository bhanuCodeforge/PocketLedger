import 'dart:convert';

import '../../../core/database/base_repository.dart';

// ── SyncService ───────────────────────────────────────────────────────────────

/// Manages the [change_log] table which acts as a local outbox for changes that
/// need to be replicated to a remote backend (e.g. Google Drive / custom API).
///
/// Usage pattern:
/// 1. Call [logChange] immediately after every insert / update / delete.
/// 2. A background worker calls [getUnsynced], ships the payload to the server,
///    then calls [markSynced] with the returned row IDs.
/// 3. Call [pruneOldSynced] periodically to keep the table lean.
class SyncService extends BaseRepository {
  static const _table = 'change_log';

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Records a mutation in the change log.
  ///
  /// [entityType] – the table name affected (e.g. 'expenses', 'income').
  /// [entityId]   – the primary-key value of the affected row.
  /// [operation]  – one of 'insert', 'update', 'delete'.
  /// [data]       – the full serialised row as a map.
  Future<void> logChange({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    assert(
      const {'insert', 'update', 'delete'}.contains(operation),
      'operation must be one of insert / update / delete',
    );

    final database = await db;
    await database.insert(_table, {
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'data': jsonEncode(data),
      'synced': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all rows that have not yet been synced, ordered oldest-first so
  /// the server can apply changes in the correct sequence.
  Future<List<Map<String, dynamic>>> getUnsynced() async {
    final database = await db;
    final rows = await database.query(
      _table,
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
    // Decode the JSON data field so callers get a fully-typed map.
    return rows.map((row) {
      final decoded = Map<String, dynamic>.from(row);
      final raw = decoded['data'];
      if (raw is String) {
        try {
          decoded['data'] = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {
          // Leave raw if decoding fails.
        }
      }
      return decoded;
    }).toList();
  }

  /// Returns the total number of pending (unsynced) changes.
  Future<int> pendingCount() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) AS cnt FROM $_table WHERE synced = 0',
    );
    return (result.first['cnt'] as int? ?? 0);
  }

  // ── Mark synced ───────────────────────────────────────────────────────────

  /// Marks the change-log rows identified by [ids] as successfully synced.
  Future<void> markSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final database = await db;
    // Split into batches of 500 to stay within SQLite parameter limits.
    const batchSize = 500;
    for (int i = 0; i < ids.length; i += batchSize) {
      final batch = ids.skip(i).take(batchSize).toList();
      final placeholders = List.filled(batch.length, '?').join(', ');
      await database.rawUpdate(
        'UPDATE $_table SET synced = 1 WHERE id IN ($placeholders)',
        batch.cast<Object>(),
      );
    }
  }

  // ── Pruning ───────────────────────────────────────────────────────────────

  /// Deletes change-log rows that have been synced and are older than
  /// [keepDays] days (default 30).  Call this periodically to prevent unbounded
  /// table growth.
  Future<int> pruneOldSynced({int keepDays = 30}) async {
    final database = await db;
    final cutoff = DateTime.now()
        .subtract(Duration(days: keepDays))
        .millisecondsSinceEpoch;
    return database.delete(
      _table,
      where: 'synced = 1 AND created_at < ?',
      whereArgs: [cutoff],
    );
  }

  /// Deletes ALL rows in the change log (e.g. after a full-reset / re-sync).
  Future<void> clearAll() async {
    final database = await db;
    await database.delete(_table);
  }

  // ── Convenience factories ─────────────────────────────────────────────────

  /// Convenience: log an insert from a model that exposes [toMap()].
  Future<void> logInsert(String entityType, String entityId,
      Map<String, dynamic> data) =>
      logChange(
          entityType: entityType,
          entityId: entityId,
          operation: 'insert',
          data: data);

  /// Convenience: log an update from a model that exposes [toMap()].
  Future<void> logUpdate(String entityType, String entityId,
      Map<String, dynamic> data) =>
      logChange(
          entityType: entityType,
          entityId: entityId,
          operation: 'update',
          data: data);

  /// Convenience: log a deletion.  [data] should contain at minimum `{'id': entityId}`.
  Future<void> logDelete(String entityType, String entityId,
      [Map<String, dynamic>? data]) =>
      logChange(
          entityType: entityType,
          entityId: entityId,
          operation: 'delete',
          data: data ?? {'id': entityId});
}
