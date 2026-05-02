import 'package:uuid/uuid.dart';
import '../../../core/database/base_repository.dart';
import 'folder.dart';

class FolderRepository extends BaseRepository {
  static const _table = 'folders';

  Future<List<Folder>> getAllFolders() async {
    final database = await db;
    final rows = await database.query(
      _table,
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(Folder.fromMap).toList();
  }

  Future<List<Folder>> getActiveFolders() async {
    final database = await db;
    final rows = await database.query(
      _table,
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(Folder.fromMap).toList();
  }

  Future<List<Folder>> getRootFolders() async {
    final database = await db;
    final rows = await database.query(
      _table,
      where: 'parent_id IS NULL AND status = ?',
      whereArgs: ['active'],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(Folder.fromMap).toList();
  }

  Future<List<Folder>> getChildFolders(String parentId) async {
    final database = await db;
    final rows = await database.query(
      _table,
      where: 'parent_id = ? AND status = ?',
      whereArgs: [parentId, 'active'],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(Folder.fromMap).toList();
  }

  Future<Folder?> getFolderById(String id) async {
    final database = await db;
    final rows =
        await database.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Folder.fromMap(rows.first);
  }

  Future<List<Folder>> getFolderTree() async {
    final all = await getActiveFolders();
    final Map<String, Folder> byId = {for (final f in all) f.id: f};
    final List<Folder> roots = [];

    for (final folder in all) {
      folder.children = [];
    }

    for (final folder in all) {
      if (folder.parentId == null) {
        roots.add(folder);
      } else {
        byId[folder.parentId]?.children.add(folder);
      }
    }
    return roots;
  }

  Future<String> createFolder(Folder folder) async {
    final database = await db;
    final id = folder.id.isEmpty ? const Uuid().v4() : folder.id;
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(_table, {
      ...folder.toMap(),
      'id': id,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<void> updateFolder(Folder folder) async {
    final database = await db;
    await database.update(
      _table,
      {...folder.toMap(), 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<void> archiveFolder(String id) async {
    final database = await db;
    final now = DateTime.now().millisecondsSinceEpoch;
    // Archive the folder and all its children recursively
    await database.update(
      _table,
      {'status': 'archived', 'updated_at': now},
      where: 'id = ? OR parent_id = ?',
      whereArgs: [id, id],
    );
  }

  Future<void> reorderFolders(List<String> ids) async {
    final database = await db;
    final batch = database.batch();
    for (var i = 0; i < ids.length; i++) {
      batch.update(
        _table,
        {'sort_order': i, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [ids[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> seedDefaultFolders() async {
    final existing = await getAllFolders();
    if (existing.isNotEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final personalId = const Uuid().v4();
    final friendsId = const Uuid().v4();
    final businessId = const Uuid().v4();

    final defaults = [
      {'id': personalId, 'name': 'Personal', 'parent_id': null, 'color': '#2563EB', 'icon': 'person', 'sort_order': 0},
      {'id': const Uuid().v4(), 'name': 'Food', 'parent_id': personalId, 'color': '#DC2626', 'icon': 'restaurant', 'sort_order': 0},
      {'id': const Uuid().v4(), 'name': 'Grocery', 'parent_id': personalId, 'color': '#16A34A', 'icon': 'shopping_cart', 'sort_order': 1},
      {'id': const Uuid().v4(), 'name': 'Utility', 'parent_id': personalId, 'color': '#D97706', 'icon': 'bolt', 'sort_order': 2},
      {'id': friendsId, 'name': 'Friends', 'parent_id': null, 'color': '#7C3AED', 'icon': 'group', 'sort_order': 1},
      {'id': businessId, 'name': 'Business', 'parent_id': null, 'color': '#0891B2', 'icon': 'business', 'sort_order': 2},
    ];

    final database = await db;
    final batch = database.batch();
    for (final f in defaults) {
      batch.insert(_table, {...f, 'status': 'active', 'created_at': now, 'updated_at': now});
    }
    await batch.commit(noResult: true);
  }
}
