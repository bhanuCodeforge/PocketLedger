/// Domain models for the Groups / Split-expense feature.

// ── SplitType ─────────────────────────────────────────────────────────────────

enum SplitType {
  equal,
  custom,
  percentage;

  String get value {
    switch (this) {
      case SplitType.equal:
        return 'equal';
      case SplitType.custom:
        return 'custom';
      case SplitType.percentage:
        return 'percentage';
    }
  }

  static SplitType fromValue(String v) {
    switch (v) {
      case 'custom':
        return SplitType.custom;
      case 'percentage':
        return SplitType.percentage;
      default:
        return SplitType.equal;
    }
  }
}

// ── SplitGroup ────────────────────────────────────────────────────────────────

class SplitGroup {
  final String id;
  final String name;
  final String description;
  final String? avatarPath;
  final int createdAt;
  final int updatedAt;

  const SplitGroup({
    required this.id,
    required this.name,
    this.description = '',
    this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SplitGroup.fromMap(Map<String, dynamic> map) => SplitGroup(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        avatarPath: map['avatar_path'] as String?,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'avatar_path': avatarPath,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  SplitGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarPath,
    int? createdAt,
    int? updatedAt,
  }) =>
      SplitGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        avatarPath: avatarPath ?? this.avatarPath,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ── GroupMember ───────────────────────────────────────────────────────────────

class GroupMember {
  final String id;
  final String groupId;
  final String? contactId;
  final String name;
  final bool isSelf;
  final int createdAt;

  const GroupMember({
    required this.id,
    required this.groupId,
    this.contactId,
    required this.name,
    this.isSelf = false,
    required this.createdAt,
  });

  factory GroupMember.fromMap(Map<String, dynamic> map) => GroupMember(
        id: map['id'] as String,
        groupId: map['group_id'] as String,
        contactId: map['contact_id'] as String?,
        name: map['name'] as String,
        isSelf: (map['is_self'] as int? ?? 0) == 1,
        createdAt: map['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'group_id': groupId,
        'contact_id': contactId,
        'name': name,
        'is_self': isSelf ? 1 : 0,
        'created_at': createdAt,
      };

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? contactId,
    String? name,
    bool? isSelf,
    int? createdAt,
  }) =>
      GroupMember(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        contactId: contactId ?? this.contactId,
        name: name ?? this.name,
        isSelf: isSelf ?? this.isSelf,
        createdAt: createdAt ?? this.createdAt,
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ── GroupTransaction ──────────────────────────────────────────────────────────

class GroupTransaction {
  final String id;
  final String groupId;
  final String paidByMemberId;
  final String description;
  final double amount;
  final String category;
  final SplitType splitType;
  final int transactionDate;
  final String note;
  final int createdAt;
  final int updatedAt;

  const GroupTransaction({
    required this.id,
    required this.groupId,
    required this.paidByMemberId,
    required this.description,
    required this.amount,
    this.category = 'other',
    this.splitType = SplitType.equal,
    required this.transactionDate,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupTransaction.fromMap(Map<String, dynamic> map) => GroupTransaction(
        id: map['id'] as String,
        groupId: map['group_id'] as String,
        paidByMemberId: map['paid_by_member_id'] as String,
        description: map['description'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String? ?? 'other',
        splitType: SplitType.fromValue(map['split_type'] as String? ?? 'equal'),
        transactionDate: map['transaction_date'] as int,
        note: map['note'] as String? ?? '',
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'group_id': groupId,
        'paid_by_member_id': paidByMemberId,
        'description': description,
        'amount': amount,
        'category': category,
        'split_type': splitType.value,
        'transaction_date': transactionDate,
        'note': note,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  GroupTransaction copyWith({
    String? id,
    String? groupId,
    String? paidByMemberId,
    String? description,
    double? amount,
    String? category,
    SplitType? splitType,
    int? transactionDate,
    String? note,
    int? createdAt,
    int? updatedAt,
  }) =>
      GroupTransaction(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        paidByMemberId: paidByMemberId ?? this.paidByMemberId,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        splitType: splitType ?? this.splitType,
        transactionDate: transactionDate ?? this.transactionDate,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ── GroupTransactionSplit ─────────────────────────────────────────────────────

class GroupTransactionSplit {
  final String id;
  final String transactionId;
  final String memberId;
  final double amount;
  final bool isSettled;
  final int? settledAt;

  const GroupTransactionSplit({
    required this.id,
    required this.transactionId,
    required this.memberId,
    required this.amount,
    this.isSettled = false,
    this.settledAt,
  });

  factory GroupTransactionSplit.fromMap(Map<String, dynamic> map) =>
      GroupTransactionSplit(
        id: map['id'] as String,
        transactionId: map['transaction_id'] as String,
        memberId: map['member_id'] as String,
        amount: (map['amount'] as num).toDouble(),
        isSettled: (map['is_settled'] as int? ?? 0) == 1,
        settledAt: map['settled_at'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'transaction_id': transactionId,
        'member_id': memberId,
        'amount': amount,
        'is_settled': isSettled ? 1 : 0,
        'settled_at': settledAt,
      };

  GroupTransactionSplit copyWith({
    String? id,
    String? transactionId,
    String? memberId,
    double? amount,
    bool? isSettled,
    int? settledAt,
  }) =>
      GroupTransactionSplit(
        id: id ?? this.id,
        transactionId: transactionId ?? this.transactionId,
        memberId: memberId ?? this.memberId,
        amount: amount ?? this.amount,
        isSettled: isSettled ?? this.isSettled,
        settledAt: settledAt ?? this.settledAt,
      );
}
