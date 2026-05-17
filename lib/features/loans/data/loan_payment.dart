class LoanPayment {
  final String id;
  final String loanId;
  final double amount;
  final String note;
  final int paymentDate;
  final int createdAt;

  const LoanPayment({
    required this.id,
    required this.loanId,
    required this.amount,
    this.note = '',
    required this.paymentDate,
    required this.createdAt,
  });

  factory LoanPayment.fromMap(Map<String, dynamic> map) => LoanPayment(
        id: map['id'] as String,
        loanId: map['loan_id'] as String,
        amount: (map['amount'] as num).toDouble(),
        note: map['note'] as String? ?? '',
        paymentDate: map['payment_date'] as int,
        createdAt: map['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'loan_id': loanId,
        'amount': amount,
        'note': note,
        'payment_date': paymentDate,
        'created_at': createdAt,
      };

  LoanPayment copyWith({
    String? id,
    String? loanId,
    double? amount,
    String? note,
    int? paymentDate,
    int? createdAt,
  }) =>
      LoanPayment(
        id: id ?? this.id,
        loanId: loanId ?? this.loanId,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        paymentDate: paymentDate ?? this.paymentDate,
        createdAt: createdAt ?? this.createdAt,
      );
}
