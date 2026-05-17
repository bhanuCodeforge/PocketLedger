import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/base_repository.dart';

// ── SmsTransaction ────────────────────────────────────────────────────────────

class SmsTransaction {
  final String sender;
  final double amount;

  /// 'debit' or 'credit'
  final String type;
  final String? merchant;
  final DateTime? date;

  const SmsTransaction({
    required this.sender,
    required this.amount,
    required this.type,
    this.merchant,
    this.date,
  });

  bool get isDebit => type == 'debit';
  bool get isCredit => type == 'credit';
}

// ── SmsService ────────────────────────────────────────────────────────────────

/// Parses bank / payment-gateway SMS messages to extract transaction details.
///
/// Duplicate detection is done via a SHA-256 hash of the message body stored
/// in [sms_import_log].
class SmsService extends BaseRepository {
  static const _table = 'sms_import_log';

  // ── Regex patterns ───────────────────────────────────────────────────────

  // Amount: ₹ 1,234.56 | Rs 1234 | Rs. 1,234.00 | INR 1234.50
  static final _amountPattern = RegExp(
    r'(?:₹|Rs\.?|INR)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  // Debit keywords
  static final _debitPattern = RegExp(
    r'\b(?:debited|deducted|withdrawn|spent|payment\s+of|paid|debit)\b',
    caseSensitive: false,
  );

  // Credit keywords
  static final _creditPattern = RegExp(
    r'\b(?:credited|received|deposited|credit|added|refund)\b',
    caseSensitive: false,
  );

  // Merchant / UPI VPA after "to" or "at"
  static final _merchantPattern = RegExp(
    r'(?:to|at|towards|for)\s+([A-Za-z][A-Za-z0-9 &\-_\.]{2,40})(?:\s|$|\.)',
    caseSensitive: false,
  );

  // Date: DD/MM/YYYY | DD-MM-YYYY | YYYY-MM-DD
  static final _datePattern = RegExp(
    r'\b(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}|\d{4}[\/\-]\d{2}[\/\-]\d{2})\b',
  );

  // Senders that are known to be bank / fintech SMS short codes.
  static final _bankSenderPattern = RegExp(
    r'^(?:VM-|AD-|BP-|BW-|JD-|TM-|[A-Z]{2}-)?'
    r'(?:HDFCBK|ICICIB|SBIINB|AXISBK|KOTAKB|PAYTM|GPAY|PHONEPE|AMAZON|YESBNK|INDUSB|FEDERAL|IDFCBK|'
    r'RBLBNK|BOBBNK|CANBNK|PUNBNK|SYNBNK|UCOBNK|UNIBNK|JUSPAY|RAZORPAY|CASHFREE)',
    caseSensitive: false,
  );

  // ── Public API ───────────────────────────────────────────────────────────

  /// Returns `true` when [sender] looks like a bank / payment-gateway address.
  bool isBankSender(String sender) =>
      _bankSenderPattern.hasMatch(sender.trim());

  /// Attempts to parse [body] for a transaction.  Returns `null` when no
  /// transaction can be reliably extracted.
  SmsTransaction? parseMessage(String sender, String body) {
    // Determine transaction direction.
    final isDebit = _debitPattern.hasMatch(body);
    final isCredit = _creditPattern.hasMatch(body);

    // Skip ambiguous or promotional messages.
    if (!isDebit && !isCredit) return null;

    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    final type = isDebit ? 'debit' : 'credit';
    final merchant = _extractMerchant(body);
    final date = _extractDate(body);

    return SmsTransaction(
      sender: sender,
      amount: amount,
      type: type,
      merchant: merchant,
      date: date,
    );
  }

  /// Returns `true` when a message with this [bodyHash] has already been
  /// imported (prevents duplicate expense creation).
  Future<bool> isDuplicate(String bodyHash) async {
    final database = await db;
    final rows = await database.query(
      _table,
      where: 'sms_body_hash = ?',
      whereArgs: [bodyHash],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Records an imported SMS in [sms_import_log].
  Future<void> logImport(
    String smsAddress,
    String bodyHash, {
    String? expenseId,
  }) async {
    final database = await db;
    await database.insert(
      _table,
      {
        'id': _generateId(),
        'sms_address': smsAddress,
        'sms_body_hash': bodyHash,
        'expense_id': expenseId,
        'import_status': 'imported',
        'imported_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Computes a SHA-256 hash of [body] normalised to lowercase + trimmed,
  /// suitable for duplicate detection.
  String computeHash(String body) {
    final normalised = body.toLowerCase().trim();
    return sha256.convert(utf8.encode(normalised)).toString();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  double? _extractAmount(String body) {
    final match = _amountPattern.firstMatch(body);
    if (match == null) return null;
    final raw = match.group(1)?.replaceAll(',', '');
    return double.tryParse(raw ?? '');
  }

  String? _extractMerchant(String body) {
    final match = _merchantPattern.firstMatch(body);
    if (match == null) return null;
    final raw = match.group(1)?.trim() ?? '';
    if (raw.length < 3) return null;
    return raw
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  DateTime? _extractDate(String body) {
    final match = _datePattern.firstMatch(body);
    if (match == null) return null;
    final raw = match.group(1) ?? '';
    return _parseDmY(raw) ?? _parseYmd(raw);
  }

  DateTime? _parseDmY(String s) {
    final parts = s.split(RegExp(r'[\/\-]'));
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    int? year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime.tryParse(
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}',
    );
  }

  DateTime? _parseYmd(String s) => DateTime.tryParse(s);

  String _generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final n = DateTime.now().microsecondsSinceEpoch % 0xFFFF;
    final suffix = n.toRadixString(16).padLeft(4, '0');
    return '${ts}_$suffix';
  }
}
