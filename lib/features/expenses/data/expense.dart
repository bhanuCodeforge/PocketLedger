import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// ── ExpenseCategory ──────────────────────────────────────────────────────────

enum ExpenseCategory {
  food,
  grocery,
  fuel,
  rent,
  medical,
  shopping,
  travel,
  entertainment,
  education,
  utilities,
  other,
}

extension ExpenseCategoryExt on ExpenseCategory {
  String get value {
    switch (this) {
      case ExpenseCategory.food:
        return 'food';
      case ExpenseCategory.grocery:
        return 'grocery';
      case ExpenseCategory.fuel:
        return 'fuel';
      case ExpenseCategory.rent:
        return 'rent';
      case ExpenseCategory.medical:
        return 'medical';
      case ExpenseCategory.shopping:
        return 'shopping';
      case ExpenseCategory.travel:
        return 'travel';
      case ExpenseCategory.entertainment:
        return 'entertainment';
      case ExpenseCategory.education:
        return 'education';
      case ExpenseCategory.utilities:
        return 'utilities';
      case ExpenseCategory.other:
        return 'other';
    }
  }

  /// Human-readable label (English fallback — UI uses l10n keys).
  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.grocery:
        return 'Grocery';
      case ExpenseCategory.fuel:
        return 'Fuel';
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.medical:
        return 'Medical';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.grocery:
        return Icons.shopping_cart_rounded;
      case ExpenseCategory.fuel:
        return Icons.local_gas_station_rounded;
      case ExpenseCategory.rent:
        return Icons.home_rounded;
      case ExpenseCategory.medical:
        return Icons.local_hospital_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.travel:
        return Icons.flight_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_rounded;
      case ExpenseCategory.education:
        return Icons.school_rounded;
      case ExpenseCategory.utilities:
        return Icons.bolt_rounded;
      case ExpenseCategory.other:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return AppColors.catFood;
      case ExpenseCategory.grocery:
        return AppColors.catGrocery;
      case ExpenseCategory.fuel:
        return AppColors.catFuel;
      case ExpenseCategory.rent:
        return AppColors.catRent;
      case ExpenseCategory.medical:
        return AppColors.catMedical;
      case ExpenseCategory.shopping:
        return AppColors.catShopping;
      case ExpenseCategory.travel:
        return AppColors.catTravel;
      case ExpenseCategory.entertainment:
        return AppColors.catEntertainment;
      case ExpenseCategory.education:
        return AppColors.catEducation;
      case ExpenseCategory.utilities:
        return AppColors.catUtilities;
      case ExpenseCategory.other:
        return AppColors.catOther;
    }
  }

  static ExpenseCategory fromValue(String value) {
    switch (value) {
      case 'food':
        return ExpenseCategory.food;
      case 'grocery':
        return ExpenseCategory.grocery;
      case 'fuel':
        return ExpenseCategory.fuel;
      case 'rent':
        return ExpenseCategory.rent;
      case 'medical':
        return ExpenseCategory.medical;
      case 'shopping':
        return ExpenseCategory.shopping;
      case 'travel':
        return ExpenseCategory.travel;
      case 'entertainment':
        return ExpenseCategory.entertainment;
      case 'education':
        return ExpenseCategory.education;
      case 'utilities':
        return ExpenseCategory.utilities;
      default:
        return ExpenseCategory.other;
    }
  }
}

// ── PaymentMode ──────────────────────────────────────────────────────────────

enum PaymentMode {
  cash,
  upi,
  card,
  netBanking,
  wallet,
  cheque,
  other,
}

extension PaymentModeExt on PaymentMode {
  String get value {
    switch (this) {
      case PaymentMode.cash:
        return 'cash';
      case PaymentMode.upi:
        return 'upi';
      case PaymentMode.card:
        return 'card';
      case PaymentMode.netBanking:
        return 'netBanking';
      case PaymentMode.wallet:
        return 'wallet';
      case PaymentMode.cheque:
        return 'cheque';
      case PaymentMode.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.card:
        return 'Card';
      case PaymentMode.netBanking:
        return 'Net Banking';
      case PaymentMode.wallet:
        return 'Wallet';
      case PaymentMode.cheque:
        return 'Cheque';
      case PaymentMode.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMode.cash:
        return Icons.payments_rounded;
      case PaymentMode.upi:
        return Icons.phone_android_rounded;
      case PaymentMode.card:
        return Icons.credit_card_rounded;
      case PaymentMode.netBanking:
        return Icons.account_balance_rounded;
      case PaymentMode.wallet:
        return Icons.account_balance_wallet_rounded;
      case PaymentMode.cheque:
        return Icons.description_rounded;
      case PaymentMode.other:
        return Icons.more_horiz_rounded;
    }
  }

  static PaymentMode fromValue(String value) {
    switch (value) {
      case 'cash':
        return PaymentMode.cash;
      case 'upi':
        return PaymentMode.upi;
      case 'card':
        return PaymentMode.card;
      case 'netBanking':
        return PaymentMode.netBanking;
      case 'wallet':
        return PaymentMode.wallet;
      case 'cheque':
        return PaymentMode.cheque;
      default:
        return PaymentMode.other;
    }
  }
}

// ── Expense model ────────────────────────────────────────────────────────────

class Expense {
  final String id;
  final String walletId;
  final String? folderId;
  final double amount;
  final ExpenseCategory category;
  final PaymentMode paymentMode;
  final String note;
  final int expenseDate; // milliseconds since epoch
  final bool isRecurring;
  final String? recurringRuleId;
  final int createdAt; // milliseconds since epoch
  final int updatedAt; // milliseconds since epoch

  const Expense({
    required this.id,
    required this.walletId,
    this.folderId,
    required this.amount,
    required this.category,
    this.paymentMode = PaymentMode.cash,
    this.note = '',
    required this.expenseDate,
    this.isRecurring = false,
    this.recurringRuleId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as String,
        walletId: map['wallet_id'] as String,
        folderId: map['folder_id'] as String?,
        amount: (map['amount'] as num).toDouble(),
        category: ExpenseCategoryExt.fromValue(map['category'] as String),
        paymentMode:
            PaymentModeExt.fromValue(map['payment_mode'] as String? ?? 'cash'),
        note: map['note'] as String? ?? '',
        expenseDate: map['expense_date'] as int,
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
        'category': category.value,
        'payment_mode': paymentMode.value,
        'note': note,
        'expense_date': expenseDate,
        'is_recurring': isRecurring ? 1 : 0,
        'recurring_rule_id': recurringRuleId,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Expense copyWith({
    String? id,
    String? walletId,
    Object? folderId = _sentinel,
    double? amount,
    ExpenseCategory? category,
    PaymentMode? paymentMode,
    String? note,
    int? expenseDate,
    bool? isRecurring,
    Object? recurringRuleId = _sentinel,
    int? createdAt,
    int? updatedAt,
  }) =>
      Expense(
        id: id ?? this.id,
        walletId: walletId ?? this.walletId,
        folderId: folderId == _sentinel ? this.folderId : folderId as String?,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        paymentMode: paymentMode ?? this.paymentMode,
        note: note ?? this.note,
        expenseDate: expenseDate ?? this.expenseDate,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringRuleId: recurringRuleId == _sentinel
            ? this.recurringRuleId
            : recurringRuleId as String?,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// Sentinel object for nullable copyWith params
const Object _sentinel = Object();
