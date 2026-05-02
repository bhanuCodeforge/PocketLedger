import 'package:flutter/material.dart';

enum WalletType { cash, bank, upi, creditCard, business, other }

extension WalletTypeExt on WalletType {
  String get value {
    switch (this) {
      case WalletType.cash:
        return 'cash';
      case WalletType.bank:
        return 'bank';
      case WalletType.upi:
        return 'upi';
      case WalletType.creditCard:
        return 'credit_card';
      case WalletType.business:
        return 'business';
      case WalletType.other:
        return 'other';
    }
  }

  IconData get icon {
    switch (this) {
      case WalletType.cash:
        return Icons.account_balance_wallet;
      case WalletType.bank:
        return Icons.account_balance;
      case WalletType.upi:
        return Icons.phone_android;
      case WalletType.creditCard:
        return Icons.credit_card;
      case WalletType.business:
        return Icons.business_center;
      case WalletType.other:
        return Icons.wallet;
    }
  }

  String get label {
    switch (this) {
      case WalletType.cash:
        return 'Cash';
      case WalletType.bank:
        return 'Bank';
      case WalletType.upi:
        return 'UPI';
      case WalletType.creditCard:
        return 'Credit Card';
      case WalletType.business:
        return 'Business';
      case WalletType.other:
        return 'Other';
    }
  }

  static WalletType fromValue(String value) {
    switch (value) {
      case 'cash':
        return WalletType.cash;
      case 'bank':
        return WalletType.bank;
      case 'upi':
        return WalletType.upi;
      case 'credit_card':
        return WalletType.creditCard;
      case 'business':
        return WalletType.business;
      default:
        return WalletType.other;
    }
  }
}

class Wallet {
  final String id;
  final String name;
  final WalletType type;
  final double openingBalance;
  final String? color;
  final String? icon;
  final String status;
  final int createdAt;
  final int updatedAt;
  final double? currentBalance;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    this.openingBalance = 0.0,
    this.color,
    this.icon,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.currentBalance,
  });

  bool get isActive => status == 'active';

  factory Wallet.fromMap(Map<String, dynamic> map) => Wallet(
        id: map['id'] as String,
        name: map['name'] as String,
        type: WalletTypeExt.fromValue(map['type'] as String),
        openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0.0,
        color: map['color'] as String?,
        icon: map['icon'] as String?,
        status: map['status'] as String? ?? 'active',
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
        currentBalance: (map['current_balance'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.value,
        'opening_balance': openingBalance,
        'color': color,
        'icon': icon,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Wallet copyWith({
    String? id,
    String? name,
    WalletType? type,
    double? openingBalance,
    String? color,
    String? icon,
    String? status,
    int? createdAt,
    int? updatedAt,
    double? currentBalance,
  }) =>
      Wallet(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        openingBalance: openingBalance ?? this.openingBalance,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        currentBalance: currentBalance ?? this.currentBalance,
      );
}
