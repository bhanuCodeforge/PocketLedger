/// Domain models for the Budgets feature.

// ── BudgetPeriod ──────────────────────────────────────────────────────────────

enum BudgetPeriod {
  monthly,
  weekly,
  yearly;

  String get value {
    switch (this) {
      case BudgetPeriod.monthly:
        return 'monthly';
      case BudgetPeriod.weekly:
        return 'weekly';
      case BudgetPeriod.yearly:
        return 'yearly';
    }
  }

  String get label {
    switch (this) {
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }

  static BudgetPeriod fromValue(String v) {
    switch (v) {
      case 'weekly':
        return BudgetPeriod.weekly;
      case 'yearly':
        return BudgetPeriod.yearly;
      default:
        return BudgetPeriod.monthly;
    }
  }
}

// ── Budget ────────────────────────────────────────────────────────────────────

class Budget {
  final String id;
  final String category;
  final String? walletId;
  final double amount;
  final BudgetPeriod period;
  final int alertAtPercent;
  final bool isActive;
  final int createdAt;
  final int updatedAt;

  const Budget({
    required this.id,
    required this.category,
    this.walletId,
    required this.amount,
    this.period = BudgetPeriod.monthly,
    this.alertAtPercent = 80,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        id: map['id'] as String,
        category: map['category'] as String,
        walletId: map['wallet_id'] as String?,
        amount: (map['amount'] as num).toDouble(),
        period: BudgetPeriod.fromValue(map['period'] as String? ?? 'monthly'),
        alertAtPercent: map['alert_at_percent'] as int? ?? 80,
        isActive: (map['is_active'] as int? ?? 1) == 1,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'wallet_id': walletId,
        'amount': amount,
        'period': period.value,
        'alert_at_percent': alertAtPercent,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Budget copyWith({
    String? id,
    String? category,
    String? walletId,
    double? amount,
    BudgetPeriod? period,
    int? alertAtPercent,
    bool? isActive,
    int? createdAt,
    int? updatedAt,
  }) =>
      Budget(
        id: id ?? this.id,
        category: category ?? this.category,
        walletId: walletId ?? this.walletId,
        amount: amount ?? this.amount,
        period: period ?? this.period,
        alertAtPercent: alertAtPercent ?? this.alertAtPercent,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ── BudgetWithSpent ───────────────────────────────────────────────────────────

class BudgetWithSpent {
  final Budget budget;
  final double spentAmount;

  const BudgetWithSpent({
    required this.budget,
    required this.spentAmount,
  });

  double get spentPercent =>
      budget.amount > 0 ? (spentAmount / budget.amount) * 100 : 0;

  double get remaining => budget.amount - spentAmount;

  bool get isExceeded => spentAmount > budget.amount;

  bool get isNearAlert => spentPercent >= budget.alertAtPercent && !isExceeded;
}
