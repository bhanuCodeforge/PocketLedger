enum LoanType {
  given,
  taken;

  String get value => name; // 'given' or 'taken'

  static LoanType fromValue(String v) =>
      v == 'taken' ? LoanType.taken : LoanType.given;
}

enum InterestType {
  none,
  simple,
  compound;

  String get value => name;

  static InterestType fromValue(String v) {
    switch (v) {
      case 'simple':
        return InterestType.simple;
      case 'compound':
        return InterestType.compound;
      default:
        return InterestType.none;
    }
  }
}

enum CompoundFrequency {
  monthly,
  quarterly,
  yearly;

  String get value => name;

  int get timesPerYear {
    switch (this) {
      case CompoundFrequency.monthly:
        return 12;
      case CompoundFrequency.quarterly:
        return 4;
      case CompoundFrequency.yearly:
        return 1;
    }
  }

  static CompoundFrequency fromValue(String v) {
    switch (v) {
      case 'quarterly':
        return CompoundFrequency.quarterly;
      case 'yearly':
        return CompoundFrequency.yearly;
      default:
        return CompoundFrequency.monthly;
    }
  }
}

class Loan {
  final String id;
  final String? contactId;
  final String contactName;
  final LoanType type;
  final double principalAmount;
  final double interestRate;
  final InterestType interestType;
  final CompoundFrequency compoundFrequency;
  final int startDate;
  final int? dueDate;
  final String note;
  final bool isSettled;
  final int? settledAt;
  final String? walletId;
  final int createdAt;
  final int updatedAt;

  const Loan({
    required this.id,
    this.contactId,
    required this.contactName,
    required this.type,
    required this.principalAmount,
    this.interestRate = 0.0,
    this.interestType = InterestType.none,
    this.compoundFrequency = CompoundFrequency.monthly,
    required this.startDate,
    this.dueDate,
    this.note = '',
    this.isSettled = false,
    this.settledAt,
    this.walletId,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Computed properties ──────────────────────────────────────────────────

  bool get isOverdue =>
      dueDate != null &&
      !isSettled &&
      DateTime.now().millisecondsSinceEpoch > dueDate!;

  double totalInterest(DateTime asOf) {
    if (interestType == InterestType.none || interestRate <= 0) return 0.0;
    final start = DateTime.fromMillisecondsSinceEpoch(startDate);
    final years = asOf.difference(start).inDays / 365.0;
    if (years <= 0) return 0.0;

    switch (interestType) {
      case InterestType.simple:
        return principalAmount * (interestRate / 100.0) * years;
      case InterestType.compound:
        final freq = compoundFrequency.timesPerYear.toDouble();
        final total = principalAmount *
            _mathPow(1 + interestRate / (100.0 * freq), freq * years);
        return total - principalAmount;
      case InterestType.none:
        return 0.0;
    }
  }

  double totalDue(DateTime asOf) => principalAmount + totalInterest(asOf);

  /// Uses dart:math pow via log/exp identity: base^exp = exp(exp * ln(base)).
  static double _mathPow(double base, double exponent) {
    if (base <= 0) return 0;
    // dart:math.pow handles fractional exponents natively via FFI/platform math.
    // Replicate manually to avoid import: e^(exp * ln(base)).
    // For typical finance values (base 1.0–1.3, exp 0–50) this is numerically stable.
    final lnBase = _ln(base);
    return _exp(exponent * lnBase);
  }

  static double _ln(double x) {
    if (x <= 0) return double.negativeInfinity;
    // Reduce range to [0.5, 1.5] via repeated halving/doubling.
    int k = 0;
    double m = x;
    const ln2 = 0.6931471805599453;
    while (m > 1.5) { m /= 2; k++; }
    while (m < 0.5) { m *= 2; k--; }
    // 6-term Taylor for ln(1 + u), u = m - 1, |u| < 0.5 → good convergence.
    final u = m - 1.0;
    final u2 = u * u;
    final u3 = u2 * u;
    final u4 = u3 * u;
    final u5 = u4 * u;
    final u6 = u5 * u;
    final lnM = u - u2/2 + u3/3 - u4/4 + u5/5 - u6/6;
    return lnM + k * ln2;
  }

  static double _exp(double x) {
    // Taylor series: e^x = sum(x^n / n!)
    double result = 1.0, term = 1.0;
    for (int i = 1; i <= 60; i++) {
      term *= x / i;
      result += term;
      if (term.abs() < 1e-12) break;
    }
    return result;
  }

  factory Loan.fromMap(Map<String, dynamic> map) => Loan(
        id: map['id'] as String,
        contactId: map['contact_id'] as String?,
        contactName: map['contact_name'] as String,
        type: LoanType.fromValue(map['type'] as String),
        principalAmount: (map['principal_amount'] as num).toDouble(),
        interestRate: (map['interest_rate'] as num?)?.toDouble() ?? 0.0,
        interestType:
            InterestType.fromValue(map['interest_type'] as String? ?? 'none'),
        compoundFrequency: CompoundFrequency.fromValue(
            map['compound_frequency'] as String? ?? 'monthly'),
        startDate: map['start_date'] as int,
        dueDate: map['due_date'] as int?,
        note: map['note'] as String? ?? '',
        isSettled: (map['is_settled'] as int? ?? 0) == 1,
        settledAt: map['settled_at'] as int?,
        walletId: map['wallet_id'] as String?,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'contact_id': contactId,
        'contact_name': contactName,
        'type': type.value,
        'principal_amount': principalAmount,
        'interest_rate': interestRate,
        'interest_type': interestType.value,
        'compound_frequency': compoundFrequency.value,
        'start_date': startDate,
        'due_date': dueDate,
        'note': note,
        'is_settled': isSettled ? 1 : 0,
        'settled_at': settledAt,
        'wallet_id': walletId,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Loan copyWith({
    String? id,
    String? contactId,
    String? contactName,
    LoanType? type,
    double? principalAmount,
    double? interestRate,
    InterestType? interestType,
    CompoundFrequency? compoundFrequency,
    int? startDate,
    int? dueDate,
    String? note,
    bool? isSettled,
    int? settledAt,
    String? walletId,
    int? createdAt,
    int? updatedAt,
  }) =>
      Loan(
        id: id ?? this.id,
        contactId: contactId ?? this.contactId,
        contactName: contactName ?? this.contactName,
        type: type ?? this.type,
        principalAmount: principalAmount ?? this.principalAmount,
        interestRate: interestRate ?? this.interestRate,
        interestType: interestType ?? this.interestType,
        compoundFrequency: compoundFrequency ?? this.compoundFrequency,
        startDate: startDate ?? this.startDate,
        dueDate: dueDate ?? this.dueDate,
        note: note ?? this.note,
        isSettled: isSettled ?? this.isSettled,
        settledAt: settledAt ?? this.settledAt,
        walletId: walletId ?? this.walletId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
