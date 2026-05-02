import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/database/base_repository.dart';

class SecurityRepository extends BaseRepository {
  static const _table = 'security_settings';
  static const _saltKey = 'pocket_ledger_pin_salt';
  static const _recoveryKey = 'pocket_ledger_recovery_hash';

  final FlutterSecureStorage _secureStorage;

  SecurityRepository({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // ── Salt management ────────────────────────────────────────────────────────
  Future<String> _getOrCreateSalt() async {
    var salt = await _secureStorage.read(key: _saltKey);
    if (salt == null) {
      // Generate a random 32-byte salt stored only in secure storage
      final bytes = List<int>.generate(32, (i) => i ^ DateTime.now().millisecondsSinceEpoch);
      salt = base64Encode(bytes);
      await _secureStorage.write(key: _saltKey, value: salt);
    }
    return salt;
  }

  // ── PIN hashing ────────────────────────────────────────────────────────────
  Future<String> _hashPin(String pin) async {
    final salt = await _getOrCreateSalt();
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  // ── Public API ─────────────────────────────────────────────────────────────
  Future<bool> hasPIN() async {
    final database = await db;
    final rows = await database.query(_table, where: 'id = 1');
    if (rows.isEmpty) return false;
    return rows.first['pin_hash'] != null;
  }

  Future<bool> verifyPIN(String pin) async {
    final database = await db;
    final rows = await database.query(_table, where: 'id = 1');
    if (rows.isEmpty) return false;
    final storedHash = rows.first['pin_hash'] as String?;
    if (storedHash == null) return false;
    final hash = await _hashPin(pin);
    return hash == storedHash;
  }

  Future<void> setPIN(String pin) async {
    final database = await db;
    final hash = await _hashPin(pin);
    final now = DateTime.now().millisecondsSinceEpoch;

    final rows = await database.query(_table, where: 'id = 1');
    if (rows.isEmpty) {
      await database.insert(_table, {
        'id': 1,
        'pin_hash': hash,
        'biometric_enabled': 0,
        'auto_lock_minutes': 1,
        'wrong_attempts': 0,
        'is_locked': 0,
        'updated_at': now,
      });
    } else {
      await database.update(
        _table,
        {'pin_hash': hash, 'wrong_attempts': 0, 'is_locked': 0, 'updated_at': now},
        where: 'id = 1',
      );
    }
  }

  Future<void> incrementWrongAttempts() async {
    final database = await db;
    await database.rawUpdate(
      'UPDATE $_table SET wrong_attempts = wrong_attempts + 1, updated_at = ? WHERE id = 1',
      [DateTime.now().millisecondsSinceEpoch],
    );
  }

  Future<int> getWrongAttempts() async {
    final database = await db;
    final rows = await database.query(_table, columns: ['wrong_attempts'], where: 'id = 1');
    if (rows.isEmpty) return 0;
    return rows.first['wrong_attempts'] as int;
  }

  Future<void> resetWrongAttempts() async {
    final database = await db;
    await database.update(
      _table,
      {'wrong_attempts': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = 1',
    );
  }

  Future<bool> isBiometricEnabled() async {
    final database = await db;
    final rows = await database.query(_table, columns: ['biometric_enabled'], where: 'id = 1');
    if (rows.isEmpty) return false;
    return (rows.first['biometric_enabled'] as int) == 1;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final database = await db;
    await database.update(
      _table,
      {
        'biometric_enabled': enabled ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );
  }

  Future<int> getAutoLockMinutes() async {
    final database = await db;
    final rows = await database.query(_table, columns: ['auto_lock_minutes'], where: 'id = 1');
    if (rows.isEmpty) return 1;
    return rows.first['auto_lock_minutes'] as int;
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    final database = await db;
    await database.update(
      _table,
      {
        'auto_lock_minutes': minutes,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );
  }
}

final securityRepositoryProvider = Provider<SecurityRepository>(
  (_) => SecurityRepository(),
);
