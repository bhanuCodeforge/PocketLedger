import 'package:flutter/material.dart';

// ── IncomeSource ─────────────────────────────────────────────────────────────

enum IncomeSource { salary, freelance, business, investment, gift, other }

extension IncomeSourceExt on IncomeSource {
  String get value {
    switch (this) {
      case IncomeSource.salary:
        return 'salary';
      case IncomeSource.freelance:
        return 'freelance';
      case IncomeSource.business:
        return 'business';
      case IncomeSource.investment:
        return 'investment';
      case IncomeSource.gift:
        return 'gift';
      case IncomeSource.other:
        return 'other';
    }
  }

  IconData get icon {
    switch (this) {
      case IncomeSource.salary:
        return Icons.badge_outlined;
      case IncomeSource.freelance:
        return Icons.laptop_outlined;
      case IncomeSource.business:
        return Icons.business_center_outlined;
      case IncomeSource.investment:
        return Icons.trending_up_outlined;
      case IncomeSource.gift:
        return Icons.card_giftcard_outlined;
      case IncomeSource.other:
        return Icons.attach_money_outlined;
    }
  }

  /// Human-readable label used when l10n is unavailable (fallback only).
  String get label {
    switch (this) {
      case IncomeSource.salary:
        return 'Salary';
      case IncomeSource.freelance:
        return 'Freelance';
      case IncomeSource.business:
        return 'Business';
      case IncomeSource.investment:
        return 'Investment';
      case IncomeSource.gift:
        return 'Gift';
      case IncomeSource.other:
        return 'Other';
    }
  }

  static IncomeSource fromValue(String value) {
    switch (value) {
      case 'salary':
        return IncomeSource.salary;
      case 'freelance':
        return IncomeSource.freelance;
      case 'business':
        return IncomeSource.business;
      case 'investment':
        return IncomeSource.investment;
      case 'gift':
        return IncomeSource.gift;
      default:
        return IncomeSource.other;
    }
  }
}

// ── Income ───────────────────────────────────────────────────────────────────

class Income {
  final String id;
  final String walletId;
  final String? folderId;
  final double amount;
  final IncomeSource source;
  final String note;
  final int incomeDate;       // milliseconds since epoch
  final bool isRecurring;
  final String? recurringRuleId;
  final int createdAt;        // milliseconds since epoch
  final int updatedAt;        // milliseconds since epoch

  const Income({
    required this.id,
    required this.walletId,
    this.folderId,
    required this.amount,
    this.source = IncomeSource.other,
    this.note = '',
    required this.incomeDate,
    this.isRecurring = false,
    this.recurringRuleId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Income.fromMap(Map<String, dynamic> map) => Income(
        id: map['id'] as String,
        walletId: map['wallet_id'] as String,
        folderId: map['folder_id'] as String?,
        amount: (map['amount'] as num).toDouble(),
        source: IncomeSourceExt.fromValue(map['source'] as String? ?? 'other'),
        note: map['note'] as String? ?? '',
        incomeDate: map['income_date'] as int,
        isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
        recurringRuleId: map['recurring_rule_id'] as String?,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'wallet_id': walletId,
        'folder_id': folderId,
        'amount': amount,
        'source': source.value,
        'note': note,
        'income_date': incomeDate,
        'is_recurring': isRecurring ? 1 : 0,
        'recurring_rule_id': recurringRuleId,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Income copyWith({
    String? id,
    String? walletId,
    Object? folderId = _sentinel,
    double? amount,
    IncomeSource? source,
    String? note,
    int? incomeDate,
    bool? isRecurring,
    Object? recurringRuleId = _sentinel,
    int? createdAt,
    int? updatedAt,
  }) =>
      Income(
        id: id ?? this.id,
        walletId: walletId ?? this.walletId,
        folderId: folderId == _sentinel
            ? this.folderId
            : folderId as String?,
        amount: amount ?? this.amount,
        source: source ?? this.source,
        note: note ?? this.note,
        incomeDate: incomeDate ?? this.incomeDate,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringRuleId: recurringRuleId == _sentinel
            ? this.recurringRuleId
            : recurringRuleId as String?,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// Sentinel value that allows copyWith to distinguish "pass null explicitly" from
// "leave unchanged" for nullable fields.
const Object _sentinel = Object();
