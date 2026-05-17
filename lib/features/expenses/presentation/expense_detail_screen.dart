import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../../folders/data/folder_repository.dart';
import '../../wallets/data/wallet_repository.dart';
import '../data/expense.dart';
import '../data/expense_providers.dart';
import '../data/expense_repository.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ExpenseDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  Expense? _expense;
  String? _walletName;
  String? _folderName;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ExpenseRepository();
      final expense = await repo.getById(widget.id);
      if (expense == null) {
        if (mounted) setState(() { _error = 'Expense not found.'; _isLoading = false; });
        return;
      }
      final walletRepo = WalletRepository();
      final wallet = await walletRepo.getWalletById(expense.walletId);
      String? folderName;
      if (expense.folderId != null) {
        final folderRepo = FolderRepository();
        final folder = await folderRepo.getFolderById(expense.folderId!);
        folderName = folder?.name;
      }
      if (mounted) {
        setState(() {
          _expense = expense;
          _walletName = wallet?.name ?? expense.walletId;
          _folderName = folderName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _delete(BuildContext context, AppLocalizations l10n) async {
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
      await ExpenseRepository().delete(widget.id);
      ref.invalidate(expensesProvider);
      ref.invalidate(todayExpenseTotalProvider);
      if (context.mounted) context.pop();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = ref.watch(currencyProvider);
    final symbol = currency['symbol'] ?? '₹';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('')),
        body: Center(
          child: Text(
            _error ?? l10n.noData,
            style: TextStyle(color: AppColors.expense),
          ),
        ),
      );
    }

    final expense = _expense!;
    final cat = expense.category;

    return Scaffold(
      appBar: AppBar(
        title: Text(cat.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: l10n.edit,
            onPressed: () async {
              await context.push('/expenses/${expense.id}/edit');
              await _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: l10n.delete,
            color: AppColors.expense,
            onPressed: () => _delete(context, l10n),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero amount card ─────────────────────────────────────────
            _AmountCard(
              expense: expense,
              symbol: symbol,
              walletName: _walletName ?? '',
            ),
            const SizedBox(height: 24),

            // ── Details card ─────────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: l10n.date,
                    value: DateFormat('MMMM d, yyyy').format(
                      DateTime.fromMillisecondsSinceEpoch(expense.expenseDate),
                    ),
                  ),
                  _Divider(),
                  _DetailRow(
                    icon: cat.icon,
                    iconColor: cat.color,
                    label: l10n.expenseCategory,
                    value: cat.label,
                  ),
                  _Divider(),
                  _DetailRow(
                    icon: expense.paymentMode.icon,
                    label: l10n.expensePaymentMode,
                    value: expense.paymentMode.label,
                  ),
                  _Divider(),
                  _DetailRow(
                    icon: Icons.account_balance_wallet_rounded,
                    label: l10n.expenseWallet,
                    value: _walletName ?? '—',
                  ),
                  if (_folderName != null) ...[
                    _Divider(),
                    _DetailRow(
                      icon: Icons.folder_rounded,
                      label: 'Folder',
                      value: _folderName!,
                    ),
                  ],
                  if (expense.note.isNotEmpty) ...[
                    _Divider(),
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: l10n.note,
                      value: expense.note,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Action row ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_rounded),
                    label: Text(l10n.edit),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await context.push('/expenses/${expense.id}/edit');
                      await _load();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.delete),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.expense,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _delete(context, l10n),
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _AmountCard extends StatelessWidget {
  final Expense expense;
  final String symbol;
  final String walletName;

  const _AmountCard({
    required this.expense,
    required this.symbol,
    required this.walletName,
  });

  @override
  Widget build(BuildContext context) {
    final cat = expense.category;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cat.color, cat.color.withAlpha(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    walletName,
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            CurrencyFormatter.formatSimple(expense.amount, symbol),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(
              DateTime.fromMillisecondsSinceEpoch(expense.expenseDate),
            ),
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: Theme.of(context).dividerColor.withAlpha(80),
      );
}
