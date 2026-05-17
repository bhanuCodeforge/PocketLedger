import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_helper.dart';

/// Service that creates encrypted, ZIP-compressed local backups of the
/// PocketLedger database and restores them on demand.
///
/// Backup file extension: `.plb` (PocketLedger Backup)
/// Format: ZIP archive containing a single JSON file (`data.json`),
/// AES-256 CBC-encrypted using a key derived from [pinHash].
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const _fileExt = '.plb';

  // ── Tables to back up ──────────────────────────────────────────────────────
  // Ordered so that FK dependencies are satisfied on restore (parents first).
  static const _tables = [
    'user_profile',
    'security_settings',
    'wallets',
    'folders',
    'tags',
    'expenses',
    'income',
    'entity_tags',
    'attachments',
    'contacts',
    'loans',
    'loan_payments',
    'groups',
    'group_members',
    'group_transactions',
    'group_transaction_splits',
    'budgets',
    'recurring_rules',
    'backup_metadata',
    'sms_import_log',
    'ai_insights',
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Creates a local backup of the entire database.
  ///
  /// Encryption key is derived from [pinHash] (SHA-256 hex string from the
  /// security repo).  The backup is saved to the app's documents directory
  /// and a record is inserted into `backup_metadata`.
  ///
  /// Returns the absolute path to the `.plb` file.
  Future<String> createLocalBackup(String pinHash) async {
    final db = await DatabaseHelper.instance.database;

    // 1. Read all tables as JSON
    final payload = await _dumpDatabase(db);
    final jsonBytes = utf8.encode(jsonEncode(payload));

    // 2. Encrypt
    final key = _deriveKey(pinHash);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(jsonBytes, iv: iv);

    // 3. ZIP the encrypted blob
    final archive = Archive();
    archive.addFile(ArchiveFile(
      'data.bin',
      encrypted.bytes.length,
      encrypted.bytes,
    ));
    // Store IV separately inside the archive
    final ivBytes = iv.bytes;
    archive.addFile(ArchiveFile('iv.bin', ivBytes.length, ivBytes));

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw StateError('ZIP encoding failed.');

    // 4. Save to documents directory
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'pocket_ledger_backup_$timestamp$_fileExt';
    final docDir = await getApplicationDocumentsDirectory();
    final filePath = '${docDir.path}/$fileName';
    await File(filePath).writeAsBytes(zipBytes);

    final fileSize = await File(filePath).length();
    final checksum = _checksum(zipBytes);

    // 5. Insert backup_metadata record
    await _insertBackupMetadata(db,
        fileName: fileName,
        fileSize: fileSize,
        checksum: checksum,
        backupType: 'manual');

    return filePath;
  }

  /// Restores the database from a `.plb` backup file.
  ///
  /// Steps: decrypt → unzip → validate → drop & recreate tables → insert data.
  Future<void> restoreFromFile(String filePath, String pinHash) async {
    final zipBytes = await File(filePath).readAsBytes();

    // 1. Unzip
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final dataBinFile = archive.findFile('data.bin');
    final ivBinFile = archive.findFile('iv.bin');
    if (dataBinFile == null || ivBinFile == null) {
      throw const FormatException('Invalid backup archive: missing data or IV.');
    }

    final encryptedBytes = dataBinFile.content as Uint8List;
    final ivBytes = ivBinFile.content as Uint8List;

    // 2. Decrypt
    final key = _deriveKey(pinHash);
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    late List<int> jsonBytes;
    try {
      jsonBytes = encrypter.decryptBytes(
        enc.Encrypted(encryptedBytes),
        iv: iv,
      );
    } catch (_) {
      throw const FormatException('Decryption failed — wrong PIN or corrupt backup.');
    }

    // 3. Parse and validate
    final dynamic rawPayload = jsonDecode(utf8.decode(jsonBytes));
    if (rawPayload is! Map<String, dynamic>) {
      throw const FormatException('Backup payload has unexpected structure.');
    }
    final payload = rawPayload;

    // 4. Drop and recreate tables, then insert data
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // Disable FK checks during restore
      await txn.execute('PRAGMA foreign_keys = OFF');

      for (final table in _tables.reversed) {
        await txn.execute('DELETE FROM $table');
      }

      for (final table in _tables) {
        final rows = payload[table];
        if (rows == null) continue;
        final rowList = rows as List<dynamic>;
        for (final row in rowList) {
          await txn.insert(
            table,
            Map<String, dynamic>.from(row as Map),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await txn.execute('PRAGMA foreign_keys = ON');
    });
  }

  /// Returns a human-readable date string of the most recent backup,
  /// or `null` if no backup has been created.
  Future<String?> getLastBackupDate() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'backup_metadata',
      columns: ['created_at'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final ts = rows.first['created_at'] as int;
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    return _formatDate(dt);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<Map<String, List<Map<String, dynamic>>>> _dumpDatabase(
    Database db,
  ) async {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final table in _tables) {
      try {
        final rows = await db.query(table);
        result[table] = rows.map((r) => Map<String, dynamic>.from(r)).toList();
      } catch (_) {
        // Table might not exist in older schema versions — skip gracefully
        result[table] = [];
      }
    }
    return result;
  }

  enc.Key _deriveKey(String pinHash) {
    // Use first 32 bytes (256 bits) of the UTF-8 encoded pin hash
    // (SHA-256 produces a 64-char hex string → 64 bytes)
    final bytes = utf8.encode(pinHash);
    final keyBytes = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      keyBytes[i] = bytes[i % bytes.length];
    }
    return enc.Key(keyBytes);
  }

  String _checksum(List<int> bytes) {
    var sum = 0;
    for (final b in bytes) {
      sum = (sum + b) & 0xFFFFFFFF;
    }
    return sum.toRadixString(16).padLeft(8, '0');
  }

  Future<void> _insertBackupMetadata(
    Database db, {
    required String fileName,
    required int fileSize,
    required String checksum,
    required String backupType,
    String? driveFileId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'backup_metadata',
      {
        'id': const Uuid().v4(),
        'file_name': fileName,
        'file_size': fileSize,
        'checksum': checksum,
        'drive_file_id': driveFileId,
        'backup_type': backupType,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }
}
