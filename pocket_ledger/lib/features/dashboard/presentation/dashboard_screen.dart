import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../generated/l10n/app_localizations.dart';

// ── DashboardScreen ──────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

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
        onPressed: () => context.push('/expenses/add'),
        icon: const Icon(Icons.add),
        label: Text(l10n.expenseAdd),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total balance card
          _BalanceCard(scheme: scheme, l10n: l10n),
          const SizedBox(height: 16),
          // Income / Expense summary row
          Row(
            children: [
              Expanded(child: _SummaryCard(
                label: l10n.dashboardThisMonthIncome,
                amount: 0,
                color: AppColors.income,
                icon: Icons.arrow_downward_rounded,
                scheme: scheme,
              )),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(
                label: l10n.dashboardThisMonthExpense,
                amount: 0,
                color: AppColors.expense,
                icon: Icons.arrow_upward_rounded,
                scheme: scheme,
              )),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.dashboardRecentTransactions,
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Icon(Icons.receipt_long_outlined,
                    size: 64, color: scheme.outlineVariant),
                const SizedBox(height: 16),
                Text(l10n.dashboardNoTransactions,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: scheme.onSurfaceVariant,
                    )),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => context.push('/expenses/add'),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.dashboardAddFirstExpense),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final ColorScheme scheme;
  final AppLocalizations l10n;
  const _BalanceCard({required this.scheme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardTotalBalance,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹ 0.00',
            style: AppTextStyles.amountLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.dashboardTodaySpent + ': ₹ 0.00',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final ColorScheme scheme;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                Text(
                  '₹ ${amount.toStringAsFixed(2)}',
                  style: AppTextStyles.titleSmall.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
