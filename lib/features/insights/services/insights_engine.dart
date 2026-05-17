import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../expenses/data/expense.dart';
import '../../income/data/income.dart';
import '../data/insight.dart';
import '../data/insight_repository.dart';

// ── BudgetWithSpent ───────────────────────────────────────────────────────────
//
// Lightweight DTO consumed by InsightsEngine.  When a full Budget data-layer is
// added, replace this with the real model and keep the engine signature stable.

class BudgetWithSpent {
  final String id;
  final String category; // matches ExpenseCategory.value
  final double limitAmount;
  final double spentAmount;
  final int periodStartMs; // start of the budget period (ms epoch)
  final int periodEndMs;   // end of the budget period (ms epoch)

  const BudgetWithSpent({
    required this.id,
    required this.category,
    required this.limitAmount,
    required this.spentAmount,
    required this.periodStartMs,
    required this.periodEndMs,
  });

  double get percentUsed =>
      limitAmount > 0 ? (spentAmount / limitAmount) * 100 : 0;

  double get remaining => limitAmount - spentAmount;
}

// ── InsightsEngine ────────────────────────────────────────────────────────────

/// Rule-based engine that analyses spending data and persists [AiInsight]
/// records.  Call [generateInsights] on app-open or after every transaction.
class InsightsEngine {
  final InsightRepository _repo;

  InsightsEngine(this._repo);

  static const _expiryDays = 7;
  static const _uuid = Uuid();

  // ── Public entry-point ───────────────────────────────────────────────────

  Future<void> generateInsights({
    required List<Expense> expenses,
    required List<Income> incomes,
    required List<BudgetWithSpent> budgets,
  }) async {
    // Purge stale insights first.
    await _repo.deleteExpired();

    final now = DateTime.now();

    await Future.wait([
      _checkSpendingSpikes(expenses, now),
      _checkBudgetRisk(budgets, now),
      _checkSavingOpportunity(expenses, incomes, now),
      _checkAnomalies(expenses, now),
    ]);
  }

  // ── Rule 1 – Spending spike ───────────────────────────────────────────────
  //
  // For each category: if this month's total > 150 % of the average of the
  // previous 3 months, emit a spendingSpike insight.

  Future<void> _checkSpendingSpikes(
      List<Expense> expenses, DateTime now) async {
    final thisMonthStart = DateTime(now.year, now.month);
    final Map<String, double> thisMonth = {};
    final Map<String, List<double>> prevMonths = {};

    for (final e in expenses) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.expenseDate);
      final cat = e.category.value;

      if (!d.isBefore(thisMonthStart)) {
        thisMonth[cat] = (thisMonth[cat] ?? 0) + e.amount;
      } else {
        // Bucket into the previous 3 calendar months only.
        for (int offset = 1; offset <= 3; offset++) {
          final start = _monthStart(now.year, now.month - offset);
          final end = _monthStart(now.year, now.month - offset + 1)
              .subtract(const Duration(milliseconds: 1));
          if (!d.isBefore(start) && !d.isAfter(end)) {
            prevMonths.putIfAbsent(cat, () => [0, 0, 0])[offset - 1] +=
                e.amount;
            break;
          }
        }
      }
    }

    for (final entry in thisMonth.entries) {
      final cat = entry.key;
      final currentTotal = entry.value;
      final history = prevMonths[cat] ?? [0, 0, 0];
      final avg = history.reduce((a, b) => a + b) / 3;

      if (avg > 0 && currentTotal > avg * 1.5) {
        // Skip if a still-active insight for this category already exists.
        final existing = await _repo.getByType(InsightType.spendingSpike);
        final alreadyExists = existing.any((i) {
          final d = i.data;
          return d != null && d['category'] == cat;
        });
        if (alreadyExists) continue;

        final pct = (((currentTotal - avg) / avg) * 100).round();
        final catLabel = _categoryLabel(cat);

        await _repo.save(AiInsight(
          id: _uuid.v4(),
          insightType: InsightType.spendingSpike,
          title: 'Spending spike in $catLabel',
          body: 'You\'ve spent ${_fmt(currentTotal)} on $catLabel this month — '
              '${pct}% above your 3-month average of ${_fmt(avg)}.',
          dataJson: jsonEncode({'category': cat, 'current': currentTotal, 'avg': avg}),
          isRead: false,
          expiresAt: _expiryFrom(now),
          createdAt: now.millisecondsSinceEpoch,
        ));
      }
    }
  }

  // ── Rule 2 – Budget risk ─────────────────────────────────────────────────
  //
  // If a budget is >= 80 % consumed and no active budgetRisk insight for this
  // budget already exists, create one.

  Future<void> _checkBudgetRisk(
      List<BudgetWithSpent> budgets, DateTime now) async {
    final existing = await _repo.getByType(InsightType.budgetRisk);

    for (final budget in budgets) {
      if (budget.percentUsed < 80) continue;

      final alreadyExists = existing.any((i) {
        final d = i.data;
        return d != null && d['budget_id'] == budget.id;
      });
      if (alreadyExists) continue;

      final pct = budget.percentUsed.round();
      final catLabel = _categoryLabel(budget.category);
      final remaining = budget.remaining;
      final daysLeft = DateTime.fromMillisecondsSinceEpoch(budget.periodEndMs)
          .difference(now)
          .inDays;

      final overBudget = remaining < 0;
      final title = overBudget
          ? '$catLabel budget exceeded'
          : '$catLabel budget at $pct%';
      final body = overBudget
          ? 'You\'ve gone ${_fmt(remaining.abs())} over your '
              '$catLabel budget.'
          : 'You have ${_fmt(remaining)} left for $catLabel '
              'with ${daysLeft.clamp(0, 999)} days remaining.';

      await _repo.save(AiInsight(
        id: _uuid.v4(),
        insightType: InsightType.budgetRisk,
        title: title,
        body: body,
        dataJson: jsonEncode({
          'budget_id': budget.id,
          'category': budget.category,
          'percent_used': pct,
          'remaining': remaining,
        }),
        isRead: false,
        expiresAt: _expiryFrom(now),
        createdAt: now.millisecondsSinceEpoch,
      ));
    }
  }

  // ── Rule 3 – Saving opportunity ──────────────────────────────────────────
  //
  // net savings = income − expenses.
  // If this month's savings > last month's savings, emit a savingOpportunity.

  Future<void> _checkSavingOpportunity(
      List<Expense> expenses, List<Income> incomes, DateTime now) async {
    final thisMonthStart = DateTime(now.year, now.month);
    final lastMonthStart = _monthStart(now.year, now.month - 1);

    double thisExpense = 0, lastExpense = 0;
    double thisIncome = 0, lastIncome = 0;

    for (final e in expenses) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.expenseDate);
      if (!d.isBefore(thisMonthStart)) {
        thisExpense += e.amount;
      } else if (!d.isBefore(lastMonthStart) && d.isBefore(thisMonthStart)) {
        lastExpense += e.amount;
      }
    }

    for (final i in incomes) {
      final d = DateTime.fromMillisecondsSinceEpoch(i.incomeDate);
      if (!d.isBefore(thisMonthStart)) {
        thisIncome += i.amount;
      } else if (!d.isBefore(lastMonthStart) && d.isBefore(thisMonthStart)) {
        lastIncome += i.amount;
      }
    }

    final thisSavings = thisIncome - thisExpense;
    final lastSavings = lastIncome - lastExpense;

    if (thisSavings <= lastSavings) return;

    // Don't duplicate for the same calendar month.
    final existing = await _repo.getByType(InsightType.savingOpportunity);
    final monthKey = '${now.year}-${now.month}';
    final alreadyExists = existing.any((i) {
      final d = i.data;
      return d != null && d['month_key'] == monthKey;
    });
    if (alreadyExists) return;

    final diff = thisSavings - lastSavings;
    final pct = lastSavings != 0
        ? ((diff / lastSavings.abs()) * 100).round()
        : 100;

    await _repo.save(AiInsight(
      id: _uuid.v4(),
      insightType: InsightType.savingOpportunity,
      title: 'Great savings this month!',
      body: 'You\'re saving ${_fmt(diff)} more than last month '
          '(${pct > 0 ? '+' : ''}$pct%). Keep it up!',
      dataJson: jsonEncode({
        'month_key': monthKey,
        'this_savings': thisSavings,
        'last_savings': lastSavings,
      }),
      isRead: false,
      expiresAt: _expiryFrom(now),
      createdAt: now.millisecondsSinceEpoch,
    ));
  }

  // ── Rule 4 – Anomaly ─────────────────────────────────────────────────────
  //
  // For each category: if a *single* transaction > 3x the average transaction
  // amount for that category (based on the last 90 days), flag it as an anomaly.

  Future<void> _checkAnomalies(
      List<Expense> expenses, DateTime now) async {
    final cutoff = now.subtract(const Duration(days: 90));

    // Group recent expenses by category.
    final Map<String, List<double>> catAmounts = {};
    for (final e in expenses) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.expenseDate);
      if (d.isBefore(cutoff)) continue;
      catAmounts.putIfAbsent(e.category.value, () => []).add(e.amount);
    }

    final existing = await _repo.getByType(InsightType.anomaly);

    for (final entry in catAmounts.entries) {
      final cat = entry.key;
      final amounts = entry.value;
      if (amounts.length < 2) continue; // need at least 2 data points

      final avg = amounts.reduce((a, b) => a + b) / amounts.length;
      final threshold = avg * 3;

      // Check the most recent transaction for this category.
      final latest = amounts.last;
      if (latest <= threshold) continue;

      // Avoid duplicate anomaly insight for the same transaction.
      final txKey = '${cat}_${latest.toStringAsFixed(2)}';
      final alreadyExists = existing.any((i) {
        final d = i.data;
        return d != null && d['tx_key'] == txKey;
      });
      if (alreadyExists) continue;

      final catLabel = _categoryLabel(cat);
      await _repo.save(AiInsight(
        id: _uuid.v4(),
        insightType: InsightType.anomaly,
        title: 'Unusual $catLabel expense',
        body: 'A recent $catLabel transaction of ${_fmt(latest)} is '
            'more than 3x your average (${_fmt(avg)}) for that category.',
        dataJson: jsonEncode({
          'category': cat,
          'amount': latest,
          'avg': avg,
          'tx_key': txKey,
        }),
        isRead: false,
        expiresAt: _expiryFrom(now),
        createdAt: now.millisecondsSinceEpoch,
      ));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  int _expiryFrom(DateTime now) =>
      now.add(const Duration(days: _expiryDays)).millisecondsSinceEpoch;

  /// Returns midnight on the first day of the given month, handling overflow.
  DateTime _monthStart(int year, int month) {
    // Dart's DateTime handles month overflow / underflow correctly.
    return DateTime(year, month);
  }

  String _fmt(double amount) =>
      '₹${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';

  String _categoryLabel(String value) {
    const labels = {
      'food': 'Food & Dining',
      'grocery': 'Grocery',
      'fuel': 'Fuel',
      'rent': 'Rent',
      'medical': 'Medical',
      'shopping': 'Shopping',
      'travel': 'Travel',
      'entertainment': 'Entertainment',
      'education': 'Education',
      'utilities': 'Utilities',
      'other': 'Other',
    };
    return labels[value] ?? value;
  }
}
