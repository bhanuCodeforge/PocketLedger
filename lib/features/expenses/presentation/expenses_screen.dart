import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../data/expense.dart';
import '../data/expense_providers.dart';
import '../data/expense_repository.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  // ── Helpers ────────────────────────────────────────────────────────────

  String _groupLabel(int epochMs, AppLocalizations l10n) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return l10n.today;
    if (d == yesterday) return l10n.yesterday;
    return DateFormat('MMMM d, yyyy').format(date);
  }

  /// Group a flat list of expenses into ordered date-buckets.
  List<({String label, List<Expense> items})> _group(
      List<Expense> expenses, AppLocalizations l10n) {
    final Map<String, List<Expense>> buckets = {};
    final List<String> order = [];
    for (final e in expenses) {
      final label = _groupLabel(e.expenseDate, l10n);
      if (!buckets.containsKey(label)) {
        buckets[label] = [];
        order.add(label);
      }
      buckets[label]!.add(e);
    }
    return [
      for (final label in order) (label: label, items: buckets[label]!),
    ];
  }

  Future<void> _confirmDelete(
      BuildContext context, Expense expense, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.expenseDelete),
        content: Text(l10n.expenseDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ExpenseRepository().delete(expense.id);
      ref.invalidate(expensesProvider);
      ref.invalidate(todayExpenseTotalProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.expenseDelete)),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final expensesAsync = ref.watch(expensesProvider);
    final currency = ref.watch(currencyProvider);
    final symbol = currency['symbol'] ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expenseTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
            tooltip: l10n.search,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/expenses/add');
          ref.invalidate(expensesProvider);
          ref.invalidate(todayExpenseTotalProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            '${l10n.error}: $e',
            style: TextStyle(color: AppColors.expense),
          ),
        ),
        data: (expenses) {
          if (expenses.isEmpty) {
            return _EmptyState(l10n: l10n);
          }
          final groups = _group(expenses, l10n);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(expensesProvider);
              ref.invalidate(todayExpenseTotalProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: groups.fold<int>(
                  0, (sum, g) => sum + 1 + g.items.length),
              itemBuilder: (context, index) {
                // Flatten groups into list items with headers
                int cursor = 0;
                for (final group in groups) {
                  if (index == cursor) {
                    return _DateHeader(
                      label: group.label,
                      total: group.items.fold(0.0, (s, e) => s + e.amount),
                      symbol: symbol,
                    );
                  }
                  cursor++;
                  final localIndex = index - cursor;
                  if (localIndex < group.items.length) {
                    final expense = group.items[localIndex];
                    return _ExpenseTile(
                      expense: expense,
                      symbol: symbol,
                      onTap: () async {
                        await context.push('/expenses/${expense.id}');
                        ref.invalidate(expensesProvider);
                        ref.invalidate(todayExpenseTotalProvider);
                      },
                      onDelete: () =>
                          _confirmDelete(context, expense, l10n),
                    );
                  }
                  cursor += group.items.length;
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }
}

// ── _DateHeader ──────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final String label;
  final double total;
  final String symbol;

  const _DateHeader({
    required this.label,
    required this.total,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            CurrencyFormatter.formatSimple(total, symbol),
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.expense,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _ExpenseTile ─────────────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String symbol;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.symbol,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = expense.category;
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: AppColors.expense,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // We handle deletion ourselves to show confirm dialog
      },
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cat.color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(cat.icon, color: cat.color, size: 22),
        ),
        title: Text(
          cat.label,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: expense.note.isNotEmpty
            ? Text(
                expense.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : Text(
                expense.paymentMode.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        trailing: Text(
          CurrencyFormatter.formatSimple(expense.amount, symbol),
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.expense,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── _EmptyState ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 72,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withAlpha(80),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noData,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.expenseAdd,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }
}
