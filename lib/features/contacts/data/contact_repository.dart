import 'package:uuid/uuid.dart';
import '../../../core/database/base_repository.dart';
import 'contact.dart';

class ContactRepository extends BaseRepository {
  static const _table = 'contacts';

  Future<List<Contact>> getAll() async {
    final database = await db;
    final rows = await database.query(_table, orderBy: 'name ASC');
    return rows.map(Contact.fromMap).toList();
  }

  Future<Contact?> getById(String id) async {
    final database = await db;
    final rows =
        await database.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Contact.fromMap(rows.first);
  }

  Future<String> create(Contact contact) async {
    final database = await db;
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(_table, {
      ...contact.toMap(),
      'id': id,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<void> update(Contact contact) async {
    final database = await db;
    await database.update(
      _table,
      {...contact.toMap(), 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<void> delete(String id) async {
    final database = await db;
    await database.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Contact>> search(String query) async {
    final database = await db;
    final q = '%${query.toLowerCase()}%';
    final rows = await database.query(
      _table,
      where: 'LOWER(name) LIKE ? OR LOWER(phone) LIKE ? OR LOWER(email) LIKE ?',
      whereArgs: [q, q, q],
      orderBy: 'name ASC',
    );
    return rows.map(Contact.fromMap).toList();
  }
}
