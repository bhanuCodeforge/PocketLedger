import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../wallets/data/wallet_providers.dart';
import '../data/budget.dart';
import '../data/budget_providers.dart';
import '../data/budget_repository.dart';

// ── Category metadata ─────────────────────────────────────────────────────────

const _categories = [
  'food',
  'grocery',
  'fuel',
  'rent',
  'medical',
  'shopping',
  'travel',
  'entertainment',
  'education',
  'utilities',
  'other',
];

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

// ── Screen ────────────────────────────────────────────────────────────────────

class AddBudgetScreen extends ConsumerStatefulWidget {
  /// When non-null, the screen edits an existing budget.
  final Budget? editBudget;

  const AddBudgetScreen({super.key, this.editBudget});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();

  String _category = 'food';
  BudgetPeriod _period = BudgetPeriod.monthly;
  String? _walletId; // null = all wallets
  double _alertPercent = 80;
  bool _saving = false;

  bool get _isEditing => widget.editBudget != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final b = widget.editBudget!;
      _category = b.category;
      _amountCtrl.text = b.amount.toStringAsFixed(2);
      _period = b.period;
      _walletId = b.walletId;
      _alertPercent = b.alertAtPercent.toDouble();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(budgetRepositoryProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final amount = double.parse(_amountCtrl.text.trim());

      if (_isEditing) {
        final updated = widget.editBudget!.copyWith(
          category: _category,
          amount: amount,
          period: _period,
          walletId: _walletId,
          alertAtPercent: _alertPercent.round(),
          updatedAt: now,
        );
        await repo.update(updated);
      } else {
        final draft = Budget(
          id: '',
          category: _category,
          walletId: _walletId,
          amount: amount,
          period: _period,
          alertAtPercent: _alertPercent.round(),
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        await repo.create(draft);
      }

      if (mounted) {
        ref.invalidate(budgetsProvider);
        ref.invalidate(budgetsWithSpentProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final walletsAsync = ref.watch(walletsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.budgetEdit : l10n.budgetAdd),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Category ────────────────────────────────────────────────────
            Text(
              l10n.category,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isSelected = cat == _category;
                  final catIcon =
                      _categoryIcons[cat] ?? Icons.receipt_outlined;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            catIcon,
                            color: isSelected ? Colors.white : scheme.onSurface,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _categoryLabels[cat] ?? cat,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : scheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Amount ──────────────────────────────────────────────────────
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.budgetLimit,
                hintText: '0.00',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                final a = double.tryParse(v?.trim() ?? '');
                if (a == null || a <= 0) return l10n.errorInvalidAmount;
                if (a > 9999999) return l10n.errorAmountTooLarge;
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Period ──────────────────────────────────────────────────────
            Text(
              'Period',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            SegmentedButton<BudgetPeriod>(
              segments: BudgetPeriod.values
                  .map((p) => ButtonSegment(
                        value: p,
                        label: Text(p.label),
                      ))
                  .toList(),
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
            const SizedBox(height: 20),

            // ── Wallet ──────────────────────────────────────────────────────
            walletsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (wallets) {
                if (wallets.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet (optional)',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String?>(
                      value: _walletId,
                      decoration: InputDecoration(
                        hintText: 'All Wallets',
                        prefixIcon:
                            const Icon(Icons.account_balance_wallet_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Wallets'),
                        ),
                        ...wallets.map(
                          (w) => DropdownMenuItem<String?>(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _walletId = v),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),

            // ── Alert threshold ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alert Threshold',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_alertPercent.round()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Get an alert when spending reaches this percentage of the limit.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            Slider(
              value: _alertPercent,
              min: 50,
              max: 100,
              divisions: 10,
              label: '${_alertPercent.round()}%',
              activeColor: AppColors.warning,
              onChanged: (v) => setState(() => _alertPercent = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('50%',
                    style: Theme.of(context).textTheme.labelSmall),
                Text('100%',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 32),

            // ── Save button ─────────────────────────────────────────────────
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditing ? l10n.save : l10n.budgetAdd),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.cancel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
