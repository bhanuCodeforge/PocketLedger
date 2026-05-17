import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../../expenses/data/expense.dart';
import '../../expenses/data/expense_providers.dart';
import '../../expenses/data/expense_repository.dart';
import '../../income/data/income_providers.dart';
import '../../income/data/income_repository.dart';

// ── Period enum ────────────────────────────────────────────────────────────────

enum _Period { thisWeek, thisMonth, thisYear, custom }

extension _PeriodLabel on _Period {
  String label(AppLocalizations l10n) {
    switch (this) {
      case _Period.thisWeek:
        return l10n.thisWeek;
      case _Period.thisMonth:
        return l10n.thisMonth;
      case _Period.thisYear:
        return l10n.thisYear;
      case _Period.custom:
        return l10n.custom;
    }
  }
}

// ── Date range helper ──────────────────────────────────────────────────────────

({int from, int to}) _periodRange(
    _Period period, DateTimeRange? custom) {
  final now = DateTime.now();
  switch (period) {
    case _Period.thisWeek:
      final startOfWeek =
          now.subtract(Duration(days: now.weekday - 1));
      final from = DateTime(
              startOfWeek.year, startOfWeek.month, startOfWeek.day)
          .millisecondsSinceEpoch;
      final to = DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
          .millisecondsSinceEpoch;
      return (from: from, to: to);
    case _Period.thisMonth:
      final from =
          DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      final to = DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
          .millisecondsSinceEpoch;
      return (from: from, to: to);
    case _Period.thisYear:
      final from = DateTime(now.year, 1, 1).millisecondsSinceEpoch;
      final to = DateTime(now.year, 12, 31, 23, 59, 59, 999)
          .millisecondsSinceEpoch;
      return (from: from, to: to);
    case _Period.custom:
      if (custom != null) {
        return (
          from: custom.start.millisecondsSinceEpoch,
          to: DateTime(custom.end.year, custom.end.month, custom.end.day,
                  23, 59, 59, 999)
              .millisecondsSinceEpoch,
        );
      }
      final from =
          DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      final to = DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
          .millisecondsSinceEpoch;
      return (from: from, to: to);
  }
}

// ── ReportsScreen ─────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  _Period _period = _Period.thisMonth;
  DateTimeRange? _customRange;
  int? _touchedPieIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = ref.watch(currencyProvider);
    final symbol = currency['symbol'] ?? '₹';
    final scheme = Theme.of(context).colorScheme;

    final range = _periodRange(_period, _customRange);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: l10n.reportExport,
            onPressed: () => _showExportSheet(context, l10n),
          ),
        ],
      ),
      body: _ReportBody(
        period: _period,
        range: range,
        symbol: symbol,
        l10n: l10n,
        scheme: scheme,
        touchedPieIndex: _touchedPieIndex,
        onPeriodChanged: (p) async {
          if (p == _Period.custom) {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: _customRange ??
                  DateTimeRange(
                    start: DateTime.now()
                        .subtract(const Duration(days: 30)),
                    end: DateTime.now(),
                  ),
            );
            if (picked != null) {
              setState(() {
                _customRange = picked;
                _period = _Period.custom;
              });
            }
          } else {
            setState(() {
              _period = p;
              _customRange = null;
            });
          }
        },
        onPieTouched: (i) => setState(() => _touchedPieIndex = i),
      ),
    );
  }

  void _showExportSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(l10n.reportExportPdf),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.reportExportPdf)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(l10n.reportExportCsv),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.reportExportCsv)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_on_outlined),
                title: Text(l10n.reportExportExcel),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.reportExportExcel)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _ReportBody (data-loading widget) ────────────────────────────────────────

class _ReportBody extends ConsumerWidget {
  final _Period period;
  final ({int from, int to}) range;
  final String symbol;
  final AppLocalizations l10n;
  final ColorScheme scheme;
  final int? touchedPieIndex;
  final void Function(_Period) onPeriodChanged;
  final void Function(int?) onPieTouched;

  const _ReportBody({
    required this.period,
    required this.range,
    required this.symbol,
    required this.l10n,
    required this.scheme,
    required this.touchedPieIndex,
    required this.onPeriodChanged,
    required this.onPieTouched,
  });

  Future<_ReportData> _loadData(WidgetRef ref) async {
    final expRepo = ref.read(expenseRepositoryProvider);
    final incRepo = ref.read(incomeRepositoryProvider);

    final expenses =
        await expRepo.getAll(fromDate: range.from, toDate: range.to);
    final income =
        await incRepo.getAll(fromDate: range.from, toDate: range.to);

    // Build last-6-months bar data
    final now = DateTime.now();
    final monthBars = <_MonthBar>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final mFrom = d.millisecondsSinceEpoch;
      final mTo = DateTime(d.year, d.month + 1, 1)
          .subtract(const Duration(milliseconds: 1))
          .millisecondsSinceEpoch;
      final expTotal = await expRepo.getTotalByDateRange(mFrom, mTo);
      final incTotal = await incRepo.getTotalByDateRange(mFrom, mTo);
      monthBars.add(_MonthBar(
        label: DateFormat('MMM').format(d),
        income: incTotal,
        expense: expTotal,
      ));
    }

    return _ReportData(
      expenses: expenses,
      totalExpense:
          expenses.fold(0.0, (s, e) => s + e.amount),
      totalIncome: income.fold(0.0, (s, i) => s + i.amount),
      monthBars: monthBars,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<_ReportData>(
      future: _loadData(ref),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('${l10n.error}: ${snap.error}'));
        }
        final data = snap.data!;
        return _ReportContent(
          data: data,
          period: period,
          symbol: symbol,
          l10n: l10n,
          scheme: scheme,
          touchedPieIndex: touchedPieIndex,
          onPeriodChanged: onPeriodChanged,
          onPieTouched: onPieTouched,
        );
      },
    );
  }
}

// ── _ReportContent ────────────────────────────────────────────────────────────

class _ReportContent extends StatelessWidget {
  final _ReportData data;
  final _Period period;
  final String symbol;
  final AppLocalizations l10n;
  final ColorScheme scheme;
  final int? touchedPieIndex;
  final void Function(_Period) onPeriodChanged;
  final void Function(int?) onPieTouched;

  const _ReportContent({
    required this.data,
    required this.period,
    required this.symbol,
    required this.l10n,
    required this.scheme,
    required this.touchedPieIndex,
    required this.onPeriodChanged,
    required this.onPieTouched,
  });

  @override
  Widget build(BuildContext context) {
    final netSavings = data.totalIncome - data.totalExpense;
    final categoryTotals = _buildCategoryTotals(data.expenses);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Period selector ──────────────────────────────────────────
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _Period.values.map((p) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(p.label(l10n)),
                  selected: p == period,
                  onSelected: (_) => onPeriodChanged(p),
                  selectedColor: AppColors.primary,
                  labelStyle: AppTextStyles.labelMedium.copyWith(
                    color: p == period
                        ? Colors.white
                        : scheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // ── Net savings card ─────────────────────────────────────────
        _NetSavingsCard(
          netSavings: netSavings,
          totalIncome: data.totalIncome,
          totalExpense: data.totalExpense,
          symbol: symbol,
          l10n: l10n,
          scheme: scheme,
        ),
        const SizedBox(height: 20),

        // ── Category pie chart ───────────────────────────────────────
        if (categoryTotals.isNotEmpty) ...[
          Text(l10n.reportByCategory, style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          _CategoryPieChart(
            categoryTotals: categoryTotals,
            totalExpense: data.totalExpense,
            touchedIndex: touchedPieIndex,
            symbol: symbol,
            onTouched: onPieTouched,
          ),
          const SizedBox(height: 20),

          // ── Category breakdown list ──────────────────────────────
          _CategoryBreakdownList(
            categoryTotals: categoryTotals,
            totalExpense: data.totalExpense,
            symbol: symbol,
            scheme: scheme,
          ),
          const SizedBox(height: 20),
        ],

        // ── Income vs Expense bar chart ──────────────────────────────
        Text(l10n.reportIncomeVsExpense, style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        _IncomeExpenseBarChart(
          bars: data.monthBars,
          symbol: symbol,
          scheme: scheme,
        ),
        const SizedBox(height: 8),

        // ── Bar chart legend ─────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: AppColors.income, label: l10n.incomeTitle),
            const SizedBox(width: 24),
            _Legend(color: AppColors.expense, label: l10n.expenseTitle),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<({ExpenseCategory cat, double total})> _buildCategoryTotals(
      List<Expense> expenses) {
    final map = <ExpenseCategory, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    final list = map.entries
        .map((entry) => (cat: entry.key, total: entry.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list;
  }
}

// ── _NetSavingsCard ───────────────────────────────────────────────────────────

class _NetSavingsCard extends StatelessWidget {
  final double netSavings;
  final double totalIncome;
  final double totalExpense;
  final String symbol;
  final AppLocalizations l10n;
  final ColorScheme scheme;

  const _NetSavingsCard({
    required this.netSavings,
    required this.totalIncome,
    required this.totalExpense,
    required this.symbol,
    required this.l10n,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = netSavings >= 0;
    final savingsColor =
        isPositive ? AppColors.income : AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reportNetSavings,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isPositive ? '+' : ''}${CurrencyFormatter.formatSimple(netSavings, symbol)}',
                      style: AppTextStyles.amountMedium.copyWith(
                        color: savingsColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: savingsColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: savingsColor,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: l10n.incomeTitle,
                  value: CurrencyFormatter.formatSimple(
                      totalIncome, symbol),
                  color: AppColors.income,
                  bgColor: AppColors.incomeLight,
                  scheme: scheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatPill(
                  label: l10n.expenseTitle,
                  value: CurrencyFormatter.formatSimple(
                      totalExpense, symbol),
                  color: AppColors.expense,
                  bgColor: AppColors.expenseLight,
                  scheme: scheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final ColorScheme scheme;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? color.withAlpha(30) : bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                AppTextStyles.labelSmall.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── _CategoryPieChart ─────────────────────────────────────────────────────────

class _CategoryPieChart extends StatelessWidget {
  final List<({ExpenseCategory cat, double total})> categoryTotals;
  final double totalExpense;
  final int? touchedIndex;
  final String symbol;
  final void Function(int?) onTouched;

  const _CategoryPieChart({
    required this.categoryTotals,
    required this.totalExpense,
    required this.touchedIndex,
    required this.symbol,
    required this.onTouched,
  });

  @override
  Widget build(BuildContext context) {
    final sections = List.generate(categoryTotals.length, (i) {
      final item = categoryTotals[i];
      final isTouched = i == touchedIndex;
      final pct = totalExpense > 0 ? item.total / totalExpense * 100 : 0.0;
      return PieChartSectionData(
        value: item.total,
        color: item.cat.color,
        radius: isTouched ? 72 : 60,
        title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        badgeWidget: isTouched
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.cat.color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  item.cat.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      );
    });

    final touchedItem =
        touchedIndex != null && touchedIndex! < categoryTotals.length
            ? categoryTotals[touchedIndex!]
            : null;

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 60,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    onTouched(null);
                  } else {
                    onTouched(
                        response.touchedSection!.touchedSectionIndex);
                  }
                },
              ),
              sectionsSpace: 2,
            ),
          ),
          // Center label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (touchedItem != null) ...[
                Icon(touchedItem.cat.icon,
                    color: touchedItem.cat.color, size: 20),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatSimple(
                      touchedItem.total, symbol),
                  style: AppTextStyles.titleSmall.copyWith(
                    color: touchedItem.cat.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                Text(
                  'Total',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatSimple(totalExpense, symbol),
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── _CategoryBreakdownList ────────────────────────────────────────────────────

class _CategoryBreakdownList extends StatelessWidget {
  final List<({ExpenseCategory cat, double total})> categoryTotals;
  final double totalExpense;
  final String symbol;
  final ColorScheme scheme;

  const _CategoryBreakdownList({
    required this.categoryTotals,
    required this.totalExpense,
    required this.symbol,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: List.generate(categoryTotals.length, (i) {
          final item = categoryTotals[i];
          final pct =
              totalExpense > 0 ? item.total / totalExpense : 0.0;
          return Column(
            children: [
              if (i > 0)
                Divider(
                    height: 1, indent: 56, color: scheme.outlineVariant),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.cat.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.cat.icon,
                          color: item.cat.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.cat.label,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatSimple(
                                    item.total, symbol),
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor:
                                        item.cat.color.withAlpha(30),
                                    valueColor:
                                        AlwaysStoppedAnimation(item.cat.color),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(pct * 100).toStringAsFixed(1)}%',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── _IncomeExpenseBarChart ────────────────────────────────────────────────────

class _IncomeExpenseBarChart extends StatelessWidget {
  final List<_MonthBar> bars;
  final String symbol;
  final ColorScheme scheme;

  const _IncomeExpenseBarChart({
    required this.bars,
    required this.symbol,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = bars.fold<double>(
          0,
          (max, b) => math.max(max, math.max(b.income, b.expense)),
        ) *
        1.2;
    final effectiveMaxY = maxY < 100 ? 100.0 : maxY;

    final groups = List.generate(bars.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: bars[i].income,
            color: AppColors.income,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: bars[i].expense,
            color: AppColors.expense,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    });

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: BarChart(
        BarChartData(
          maxY: effectiveMaxY,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: scheme.outlineVariant,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (v, meta) {
                  if (v == 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _compactNumber(v),
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= bars.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      bars[idx].label,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.surfaceContainerHighest,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label =
                    rodIndex == 0 ? 'Income' : 'Expense';
                return BarTooltipItem(
                  '$label\n$symbol${rod.toY.toStringAsFixed(0)}',
                  TextStyle(
                    color: rod.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          barGroups: groups,
        ),
      ),
    );
  }

  String _compactNumber(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ── _Legend ───────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _ReportData {
  final List<Expense> expenses;
  final double totalExpense;
  final double totalIncome;
  final List<_MonthBar> monthBars;

  const _ReportData({
    required this.expenses,
    required this.totalExpense,
    required this.totalIncome,
    required this.monthBars,
  });
}

class _MonthBar {
  final String label;
  final double income;
  final double expense;

  const _MonthBar({
    required this.label,
    required this.income,
    required this.expense,
  });
}
