import 'dart:convert';

// ── InsightType ───────────────────────────────────────────────────────────────

enum InsightType {
  spendingSpike,
  budgetRisk,
  savingOpportunity,
  anomaly;

  String get value {
    switch (this) {
      case InsightType.spendingSpike:
        return 'spending_spike';
      case InsightType.budgetRisk:
        return 'budget_risk';
      case InsightType.savingOpportunity:
        return 'saving_opportunity';
      case InsightType.anomaly:
        return 'anomaly';
    }
  }

  static InsightType fromValue(String value) {
    switch (value) {
      case 'spending_spike':
        return InsightType.spendingSpike;
      case 'budget_risk':
        return InsightType.budgetRisk;
      case 'saving_opportunity':
        return InsightType.savingOpportunity;
      case 'anomaly':
        return InsightType.anomaly;
      default:
        return InsightType.anomaly;
    }
  }
}

// ── AiInsight ─────────────────────────────────────────────────────────────────

class AiInsight {
  final String id;
  final InsightType insightType;
  final String title;
  final String body;

  /// Nullable JSON string carrying extra structured data for the insight.
  final String? dataJson;
  final bool isRead;

  /// Milliseconds since epoch – insight expires and should be hidden after this.
  final int expiresAt;

  /// Milliseconds since epoch.
  final int createdAt;

  const AiInsight({
    required this.id,
    required this.insightType,
    required this.title,
    required this.body,
    this.dataJson,
    this.isRead = false,
    required this.expiresAt,
    required this.createdAt,
  });

  // ── Serialisation ────────────────────────────────────────────────────────

  factory AiInsight.fromMap(Map<String, dynamic> map) => AiInsight(
        id: map['id'] as String,
        insightType: InsightType.fromValue(map['insight_type'] as String),
        title: map['title'] as String,
        body: map['body'] as String,
        dataJson: map['data'] as String?,
        isRead: (map['is_read'] as int? ?? 0) == 1,
        expiresAt: map['expires_at'] as int,
        createdAt: map['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'insight_type': insightType.value,
        'title': title,
        'body': body,
        'data': dataJson,
        'is_read': isRead ? 1 : 0,
        'expires_at': expiresAt,
        'created_at': createdAt,
      };

  /// Convenience: decode [dataJson] into a typed map when it is not null.
  Map<String, dynamic>? get data =>
      dataJson != null ? jsonDecode(dataJson!) as Map<String, dynamic> : null;

  // ── copyWith ─────────────────────────────────────────────────────────────

  AiInsight copyWith({
    String? id,
    InsightType? insightType,
    String? title,
    String? body,
    Object? dataJson = _sentinel,
    bool? isRead,
    int? expiresAt,
    int? createdAt,
  }) =>
      AiInsight(
        id: id ?? this.id,
        insightType: insightType ?? this.insightType,
        title: title ?? this.title,
        body: body ?? this.body,
        dataJson:
            dataJson == _sentinel ? this.dataJson : dataJson as String?,
        isRead: isRead ?? this.isRead,
        expiresAt: expiresAt ?? this.expiresAt,
        createdAt: createdAt ?? this.createdAt,
      );
}

// Sentinel value so copyWith can distinguish "pass null" from "leave unchanged".
const Object _sentinel = Object();
