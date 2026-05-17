import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../data/income.dart';
import '../data/income_providers.dart';
import '../data/income_repository.dart';

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  // ── Delete ───────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(BuildContext context, Income income) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(
          '${_sourceLabel(income.source, l10n)} — ${_formatAmount(income.amount)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(incomeRepositoryProvider).delete(income.id);
      ref.invalidate(incomeListProvider);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatAmount(double amount) {
    final currency = ref.read(currencyProvider);
    return CurrencyFormatter.formatSimple(amount, currency['symbol'] ?? '₹');
  }

  String _sourceLabel(IncomeSource source, AppLocalizations l10n) {
    switch (source) {
      case IncomeSource.salary:
        return l10n.incomeSourceSalary;
      case IncomeSource.freelance:
        return l10n.incomeSourceFreelance;
      case IncomeSource.business:
        return l10n.incomeSourceBusiness;
      case IncomeSource.investment:
        return l10n.incomeSourceInvestment;
      case IncomeSource.gift:
        return l10n.incomeSourceGift;
      case IncomeSource.other:
        return l10n.incomeSourceOther;
    }
  }

  /// Returns a section header string: "Today", "Yesterday", or "dd MMM yyyy".
  String _dateHeader(int ms) {
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _timeLabel(int ms) =>
      DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(ms));

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final incomeAsync = ref.watch(incomeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.incomeTitle),
        actions: [
          // Month total badge
          incomeAsync.when(
            data: (list) {
              final now = DateTime.now();
              final monthTotal = list
                  .where((i) {
                    final d = DateTime.fromMillisecondsSinceEpoch(i.incomeDate);
                    return d.year == now.year && d.month == now.month;
                  })
                  .fold<double>(0, (sum, i) => sum + i.amount);
              final currency = ref.read(currencyProvider);
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    CurrencyFormatter.formatSimple(
                        monthTotal, currency['symbol'] ?? '₹'),
                    style: AppTextStyles.titleSmall
                        .copyWith(color: AppColors.income),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/income/add'),
        backgroundColor: AppColors.income,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: incomeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (list) {
          if (list.isEmpty) return _EmptyState(l10n: l10n, scheme: scheme);
          return _GroupedList(
            incomes: list,
            l10n: l10n,
            scheme: scheme,
            dateHeader: _dateHeader,
            timeLabel: _timeLabel,
            sourceLabel: _sourceLabel,
            formatAmount: _formatAmount,
            onDelete: (income) => _confirmDelete(context, income),
            onTap: (income) => context.push('/income/${income.id}/edit'),
          );
        },
      ),
    );
  }
}

// ── Grouped list ──────────────────────────────────────────────────────────────

class _GroupedList extends StatelessWidget {
  final List<Income> incomes;
  final AppLocalizations l10n;
  final ColorScheme scheme;
  final String Function(int ms) dateHeader;
  final String Function(int ms) timeLabel;
  final String Function(IncomeSource, AppLocalizations) sourceLabel;
  final String Function(double) formatAmount;
  final void Function(Income) onDelete;
  final void Function(Income) onTap;

  const _GroupedList({
    required this.incomes,
    required this.l10n,
    required this.scheme,
    required this.dateHeader,
    required this.timeLabel,
    required this.sourceLabel,
    required this.formatAmount,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Build ordered list of (header | income) items.
    final items = <Object>[];
    String? lastHeader;
    for (final income in incomes) {
      final header = dateHeader(income.incomeDate);
      if (header != lastHeader) {
        items.add(header);
        lastHeader = header;
      }
      items.add(income);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is String) {
          return _SectionHeader(title: item, scheme: scheme);
        }
        final income = item as Income;
        return _IncomeCard(
          income: income,
          l10n: l10n,
          scheme: scheme,
          sourceLabel: sourceLabel(income.source, l10n),
          timeLabel: timeLabel(income.incomeDate),
          amountLabel: formatAmount(income.amount),
          onDelete: () => onDelete(income),
          onTap: () => onTap(income),
        );
      },
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final ColorScheme scheme;

  const _SectionHeader({required this.title, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: AppTextStyles.labelMedium.copyWith(
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Income card with swipe-to-delete ──────────────────────────────────────────

class _IncomeCard extends StatelessWidget {
  final Income income;
  final AppLocalizations l10n;
  final ColorScheme scheme;
  final String sourceLabel;
  final String timeLabel;
  final String amountLabel;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _IncomeCard({
    required this.income,
    required this.l10n,
    required this.scheme,
    required this.sourceLabel,
    required this.timeLabel,
    required this.amountLabel,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(income.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.expense,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        // We handle the actual deletion inside onDelete (with dialog), so
        // returning false here prevents Dismissible from removing the tile
        // itself — the list rebuild from invalidation will do it.
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Source icon pill
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.incomeLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    income.source.icon,
                    color: AppColors.income,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Source + note
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sourceLabel,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: scheme.onSurface,
                          )),
                      if (income.note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          income.note,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        timeLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  amountLabel,
                  style: AppTextStyles.amountSmall.copyWith(
                    color: AppColors.income,
                  ),
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
  final AppLocalizations l10n;
  final ColorScheme scheme;

  const _EmptyState({required this.l10n, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 72,
            color: scheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noData,
            style: AppTextStyles.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/income/add'),
            icon: const Icon(Icons.add),
            label: Text(l10n.incomeAdd),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.income,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.expense),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
