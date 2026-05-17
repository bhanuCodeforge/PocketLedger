import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../../expenses/data/expense.dart';
import '../../expenses/data/expense_providers.dart';
import '../../income/data/income.dart';
import '../../income/data/income_providers.dart';
import '../../wallets/data/wallet.dart';
import '../../wallets/data/wallet_providers.dart';

// ── Additional providers needed for monthly totals ────────────────────────────

final _currentMonthExpenseTotalProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
  final to = DateTime(now.year, now.month + 1, 1)
      .subtract(const Duration(milliseconds: 1))
      .millisecondsSinceEpoch;
  return repo.getTotalByDateRange(from, to);
});

// ── Unified transaction type for display ──────────────────────────────────────

sealed class _Transaction {
  int get dateMs;
  double get amount;
}

class _ExpenseTx extends _Transaction {
  final Expense e;
  _ExpenseTx(this.e);
  @override
  int get dateMs => e.expenseDate;
  @override
  double get amount => e.amount;
}

class _IncomeTx extends _Transaction {
  final Income i;
  _IncomeTx(this.i);
  @override
  int get dateMs => i.incomeDate;
  @override
  double get amount => i.amount;
}

// ── Recent-transactions provider (last 10 mixed) ──────────────────────────────

final _recentTransactionsProvider =
    FutureProvider<List<_Transaction>>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  final income = await ref.watch(incomeListProvider.future);

  final all = <_Transaction>[
    ...expenses.map(_ExpenseTx.new),
    ...income.map(_IncomeTx.new),
  ]..sort((a, b) => b.dateMs.compareTo(a.dateMs));

  return all.take(10).toList();
});

// ── DashboardScreen ───────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<void> _refresh() async {
    ref.invalidate(walletsProvider);
    ref.invalidate(todayExpenseTotalProvider);
    ref.invalidate(todayIncomeTotalProvider);
    ref.invalidate(currentMonthIncomeTotalProvider);
    ref.invalidate(_currentMonthExpenseTotalProvider);
    ref.invalidate(expensesProvider);
    ref.invalidate(incomeListProvider);
    ref.invalidate(_recentTransactionsProvider);
    // Allow providers to rebuild
    await Future.wait([
      ref.read(walletsProvider.future),
      ref.read(_recentTransactionsProvider.future),
    ]);
  }

  String _dateLabel(int epochMs, AppLocalizations l10n) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return l10n.today;
    if (d == yesterday) return l10n.yesterday;
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currency = ref.watch(currencyProvider);
    final symbol = currency['symbol'] ?? '₹';

    final walletsAsync = ref.watch(walletsProvider);
    final todayExpenseAsync = ref.watch(todayExpenseTotalProvider);
    final todayIncomeAsync = ref.watch(todayIncomeTotalProvider);
    final monthIncomeAsync = ref.watch(currentMonthIncomeTotalProvider);
    final monthExpenseAsync = ref.watch(_currentMonthExpenseTotalProvider);
    final recentAsync = ref.watch(_recentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/expenses/add');
          _refresh();
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.expenseAdd),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            // ── Total balance card ───────────────────────────────────────
            _BalanceCard(
              walletsAsync: walletsAsync,
              todayExpenseAsync: todayExpenseAsync,
              todayIncomeAsync: todayIncomeAsync,
              symbol: symbol,
              l10n: l10n,
              onAddIncome: () async {
                await context.push('/income/add');
                _refresh();
              },
            ),
            const SizedBox(height: 16),

            // ── This month summary row ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: l10n.dashboardThisMonthIncome,
                    asyncValue: monthIncomeAsync,
                    color: AppColors.income,
                    bgColor: AppColors.incomeLight,
                    icon: Icons.arrow_downward_rounded,
                    symbol: symbol,
                    scheme: scheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: l10n.dashboardThisMonthExpense,
                    asyncValue: monthExpenseAsync,
                    color: AppColors.expense,
                    bgColor: AppColors.expenseLight,
                    icon: Icons.arrow_upward_rounded,
                    symbol: symbol,
                    scheme: scheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Recent transactions ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.dashboardRecentTransactions,
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/expenses'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            recentAsync.when(
              loading: () => const _ShimmerList(),
              error: (e, _) => Center(
                child: Text('${l10n.error}: $e',
                    style: TextStyle(color: AppColors.expense)),
              ),
              data: (txs) {
                if (txs.isEmpty) {
                  return _EmptyTransactions(l10n: l10n, scheme: scheme);
                }
                return Column(
                  children: [
                    for (final tx in txs)
                      _TransactionTile(
                        tx: tx,
                        symbol: symbol,
                        dateLabel: _dateLabel(tx.dateMs, l10n),
                        onTap: () async {
                          if (tx is _ExpenseTx) {
                            await context.push('/expenses/${tx.e.id}');
                            _refresh();
                          }
                          // Income detail screen not routed yet — no-op
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── _BalanceCard ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final AsyncValue<List<Wallet>> walletsAsync;
  final AsyncValue<double> todayExpenseAsync;
  final AsyncValue<double> todayIncomeAsync;
  final String symbol;
  final AppLocalizations l10n;
  final VoidCallback onAddIncome;

  const _BalanceCard({
    required this.walletsAsync,
    required this.todayExpenseAsync,
    required this.todayIncomeAsync,
    required this.symbol,
    required this.l10n,
    required this.onAddIncome,
  });

  @override
  Widget build(BuildContext context) {
    final balanceText = walletsAsync.when(
      loading: () => '...',
      error: (_, __) => '—',
      data: (wallets) {
        final total = wallets.fold<double>(
          0.0,
          (sum, w) => sum + (w.currentBalance ?? w.openingBalance),
        );
        return CurrencyFormatter.formatSimple(total, symbol);
      },
    );

    final todayExpText = todayExpenseAsync.when(
      loading: () => '...',
      error: (_, __) => '—',
      data: (v) => CurrencyFormatter.formatSimple(v, symbol),
    );

    final todayIncText = todayIncomeAsync.when(
      loading: () => '...',
      error: (_, __) => '—',
      data: (v) => CurrencyFormatter.formatSimple(v, symbol),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardTotalBalance,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withAlpha(200),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            balanceText,
            style: AppTextStyles.amountLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _BalanceStat(
                label: l10n.today,
                prefix: '+',
                value: todayIncText,
                color: const Color(0xFF86EFAC), // green-300
              ),
              const SizedBox(width: 24),
              _BalanceStat(
                label: l10n.dashboardTodaySpent,
                prefix: '-',
                value: todayExpText,
                color: const Color(0xFFFCA5A5), // red-300
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String prefix;
  final String value;
  final Color color;

  const _BalanceStat({
    required this.label,
    required this.prefix,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white.withAlpha(180),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$prefix$value',
          style: AppTextStyles.titleSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

// ── _SummaryCard ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final AsyncValue<double> asyncValue;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final String symbol;
  final ColorScheme scheme;

  const _SummaryCard({
    required this.label,
    required this.asyncValue,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.symbol,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? color.withAlpha(40) : bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                asyncValue.when(
                  loading: () => const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => Text('—',
                      style: AppTextStyles.titleSmall.copyWith(color: color)),
                  data: (v) => Text(
                    CurrencyFormatter.formatSimple(v, symbol),
                    style: AppTextStyles.titleSmall.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── _TransactionTile ──────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final _Transaction tx;
  final String symbol;
  final String dateLabel;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.tx,
    required this.symbol,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final IconData icon;
    final Color iconColor;
    final String title;
    final String subtitle;
    final Color amountColor;
    final String amountPrefix;

    if (tx is _ExpenseTx) {
      final e = (tx as _ExpenseTx).e;
      icon = e.category.icon;
      iconColor = e.category.color;
      title = e.category.label;
      subtitle = e.note.isNotEmpty ? e.note : e.paymentMode.label;
      amountColor = AppColors.expense;
      amountPrefix = '-';
    } else {
      final i = (tx as _IncomeTx).i;
      icon = i.source.icon;
      iconColor = AppColors.income;
      title = i.source.label;
      subtitle = i.note.isNotEmpty ? i.note : i.source.label;
      amountColor = AppColors.income;
      amountPrefix = '+';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${CurrencyFormatter.formatSimple(tx.amount, symbol)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── _EmptyTransactions ────────────────────────────────────────────────────────

class _EmptyTransactions extends StatelessWidget {
  final AppLocalizations l10n;
  final ColorScheme scheme;

  const _EmptyTransactions({required this.l10n, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: scheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              l10n.dashboardNoTransactions,
              style: AppTextStyles.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.push('/expenses/add'),
              icon: const Icon(Icons.add),
              label: Text(l10n.dashboardAddFirstExpense),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _ShimmerList (loading skeleton) ──────────────────────────────────────────

class _ShimmerList extends StatefulWidget {
  const _ShimmerList();

  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final base = scheme.surfaceContainerHighest;
        final highlight = scheme.surfaceContainerHigh;
        final color = Color.lerp(base, highlight, _anim.value)!;
        return Column(
          children: List.generate(5, (i) => _ShimmerRow(color: color)),
        );
      },
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  final Color color;
  const _ShimmerRow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 80,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 14,
            width: 70,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
