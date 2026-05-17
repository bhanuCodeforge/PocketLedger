import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../data/budget.dart';
import '../data/budget_providers.dart';
import '../data/budget_repository.dart';

// ── Category helpers ──────────────────────────────────────────────────────────

const _categoryIcons = {
  'food': Icons.restaurant,
  'grocery': Icons.shopping_cart_outlined,
  'fuel': Icons.local_gas_station_outlined,
  'rent': Icons.home_outlined,
  'medical': Icons.local_hospital_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'travel': Icons.flight_outlined,
  'entertainment': Icons.movie_outlined,
  'education': Icons.school_outlined,
  'utilities': Icons.bolt_outlined,
  'other': Icons.receipt_outlined,
};

const _categoryColors = {
  'food': AppColors.catFood,
  'grocery': AppColors.catGrocery,
  'fuel': AppColors.catFuel,
  'rent': AppColors.catRent,
  'medical': AppColors.catMedical,
  'shopping': AppColors.catShopping,
  'travel': AppColors.catTravel,
  'entertainment': AppColors.catEntertainment,
  'education': AppColors.catEducation,
  'utilities': AppColors.catUtilities,
  'other': AppColors.catOther,
};

const _categoryLabels = {
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

// ── Screen ────────────────────────────────────────────────────────────────────

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final budgetsAsync = ref.watch(budgetsWithSpentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgetTitle),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/budgets/add');
          ref.invalidate(budgetsWithSpentProvider);
          ref.invalidate(budgetsProvider);
        },
        tooltip: l10n.budgetAdd,
        child: const Icon(Icons.add),
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.expense),
              const SizedBox(height: 12),
              Text('Error: $e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(budgetsWithSpentProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(
              onAdd: () async {
                await context.push('/budgets/add');
                ref.invalidate(budgetsWithSpentProvider);
                ref.invalidate(budgetsProvider);
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(budgetsWithSpentProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _BudgetCard(
                  item: item,
                  onEdit: () async {
                    await context.push('/budgets/add', extra: item.budget);
                    ref.invalidate(budgetsWithSpentProvider);
                    ref.invalidate(budgetsProvider);
                  },
                  onDelete: () async {
                    final confirmed = await _confirmDelete(context, l10n);
                    if (!confirmed) return;
                    await BudgetRepository().delete(item.budget.id);
                    ref.invalidate(budgetsWithSpentProvider);
                    ref.invalidate(budgetsProvider);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: const Text('Delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ).then((v) => v ?? false);
  }
}

// ── Budget card ───────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  final BudgetWithSpent item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  /// Progress bar color based on spent percentage.
  Color _progressColor(double pct) {
    if (pct >= 100) return AppColors.expense;
    if (pct >= 80) return Colors.orange;
    if (pct >= 50) return AppColors.warning;
    return AppColors.income;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final budget = item.budget;
    final pct = item.spentPercent.clamp(0, 100).toDouble();
    final catColor = _categoryColors[budget.category] ?? AppColors.catOther;
    final catIcon =
        _categoryIcons[budget.category] ?? Icons.receipt_outlined;
    final catLabel =
        _categoryLabels[budget.category] ?? budget.category;
    final scheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // we manage state manually
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(catIcon, color: catColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                catLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  budget.period.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (item.isExceeded) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.expenseLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Exceeded!',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.expense,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ] else if (item.isNearAlert) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${budget.alertAtPercent}% alert',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.edit),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline,
                                  color: AppColors.expense, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.delete,
                                  style: const TextStyle(
                                      color: AppColors.expense)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (val) {
                        if (val == 'edit') onEdit();
                        if (val == 'delete') onDelete();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: _progressColor(item.spentPercent),
                  ),
                ),
                const SizedBox(height: 10),

                // Amounts row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.budgetSpent,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: scheme.onSurfaceVariant),
                          ),
                          Text(
                            '₹${item.spentAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item.isExceeded
                                  ? AppColors.expense
                                  : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _progressColor(item.spentPercent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l10n.budgetLimit,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: scheme.onSurfaceVariant),
                          ),
                          Text(
                            '₹${budget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Remaining
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${l10n.budgetRemaining}: ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      item.remaining >= 0
                          ? '₹${item.remaining.toStringAsFixed(2)}'
                          : '-₹${item.remaining.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: item.remaining >= 0
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.budgetTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Set spending limits per category to stay on track.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.budgetAdd),
            ),
          ],
        ),
      ),
    );
  }
}
