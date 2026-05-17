import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../../folders/data/folder.dart';
import '../../folders/data/folder_providers.dart';
import '../../wallets/data/wallet.dart';
import '../../wallets/data/wallet_providers.dart';
import '../data/expense.dart';
import '../data/expense_providers.dart';
import '../data/expense_repository.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String? editId;
  const AddExpenseScreen({super.key, this.editId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.food;
  PaymentMode _paymentMode = PaymentMode.cash;
  String? _walletId;
  String? _folderId;
  DateTime _expenseDate = DateTime.now();
  List<String> _tags = [];
  bool _isSaving = false;
  bool _isLoading = true;
  Expense? _editingExpense;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    // Load wallets to pick default
    final wallets = await ref.read(walletsProvider.future);
    String? defaultWalletId = wallets.isNotEmpty ? wallets.first.id : null;

    if (widget.editId != null) {
      final repo = ExpenseRepository();
      final expense = await repo.getById(widget.editId!);
      if (expense != null && mounted) {
        _editingExpense = expense;
        _amountController.text = expense.amount.toStringAsFixed(2);
        _noteController.text = expense.note;
        _category = expense.category;
        _paymentMode = expense.paymentMode;
        _walletId = expense.walletId;
        _folderId = expense.folderId;
        _expenseDate =
            DateTime.fromMillisecondsSinceEpoch(expense.expenseDate);
      }
    } else {
      _walletId = defaultWalletId;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ── Actions ────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _expenseDate = picked);
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || _tags.contains(trimmed)) return;
    setState(() {
      _tags.add(trimmed);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).expenseWallet),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final repo = ExpenseRepository();
      final amount = double.parse(_amountController.text.trim());
      final now = DateTime.now().millisecondsSinceEpoch;

      if (_editingExpense != null) {
        await repo.update(_editingExpense!.copyWith(
          walletId: _walletId,
          folderId: _folderId,
          amount: amount,
          category: _category,
          paymentMode: _paymentMode,
          note: _noteController.text.trim(),
          expenseDate: _expenseDate.millisecondsSinceEpoch,
          updatedAt: now,
        ));
      } else {
        await repo.create(Expense(
          id: const Uuid().v4(),
          walletId: _walletId!,
          folderId: _folderId,
          amount: amount,
          category: _category,
          paymentMode: _paymentMode,
          note: _noteController.text.trim(),
          expenseDate: _expenseDate.millisecondsSinceEpoch,
          isRecurring: false,
          createdAt: now,
          updatedAt: now,
        ));
      }

      ref.invalidate(expensesProvider);
      ref.invalidate(todayExpenseTotalProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).save),
            backgroundColor: AppColors.income,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).error}: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.editId != null;
    final currency = ref.watch(currencyProvider);
    final symbol = currency['symbol'] ?? '₹';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(isEditing ? l10n.expenseEdit : l10n.expenseAdd)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.expenseEdit : l10n.expenseAdd),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.save,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Amount ──────────────────────────────────────────────────
            _AmountField(
              controller: _amountController,
              symbol: symbol,
              l10n: l10n,
            ),
            const SizedBox(height: 24),

            // ── Category ─────────────────────────────────────────────────
            _SectionLabel(label: l10n.expenseCategory),
            const SizedBox(height: 8),
            _CategoryGrid(
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
              l10n: l10n,
            ),
            const SizedBox(height: 24),

            // ── Payment mode ──────────────────────────────────────────────
            _SectionLabel(label: l10n.expensePaymentMode),
            const SizedBox(height: 8),
            _PaymentModeChips(
              selected: _paymentMode,
              onSelected: (p) => setState(() => _paymentMode = p),
              l10n: l10n,
            ),
            const SizedBox(height: 24),

            // ── Wallet ────────────────────────────────────────────────────
            _SectionLabel(label: l10n.expenseWallet),
            const SizedBox(height: 8),
            _WalletDropdown(
              selectedWalletId: _walletId,
              onChanged: (id) => setState(() => _walletId = id),
              l10n: l10n,
            ),
            const SizedBox(height: 24),

            // ── Folder (optional) ─────────────────────────────────────────
            _SectionLabel(label: 'Folder (optional)'),
            const SizedBox(height: 8),
            _FolderDropdown(
              selectedFolderId: _folderId,
              onChanged: (id) => setState(() => _folderId = id),
            ),
            const SizedBox(height: 24),

            // ── Date ──────────────────────────────────────────────────────
            _SectionLabel(label: l10n.date),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon:
                      const Icon(Icons.calendar_today_rounded),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                child: Text(
                  DateFormat('MMMM d, yyyy').format(_expenseDate),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Note ──────────────────────────────────────────────────────
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.expenseNote,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // ── Tags ──────────────────────────────────────────────────────
            _SectionLabel(label: l10n.expenseTags),
            const SizedBox(height: 8),
            _TagInput(
              tags: _tags,
              controller: _tagController,
              onAdd: _addTag,
              onRemove: _removeTag,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      );
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String symbol;
  final AppLocalizations l10n;
  const _AmountField(
      {required this.controller, required this.symbol, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: Theme.of(context)
          .textTheme
          .headlineMedium
          ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.expense),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: l10n.expenseAmount,
        prefixText: '$symbol ',
        prefixStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.expense,
            ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return l10n.required;
        final n = double.tryParse(v.trim());
        if (n == null || n <= 0) return l10n.errorInvalidAmount;
        if (n > 9999999) return l10n.errorAmountTooLarge;
        return null;
      },
      autofocus: true,
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onSelected;
  final AppLocalizations l10n;

  const _CategoryGrid({
    required this.selected,
    required this.onSelected,
    required this.l10n,
  });

  String _catLabel(ExpenseCategory c, AppLocalizations l10n) {
    switch (c) {
      case ExpenseCategory.food:
        return l10n.categoryFood;
      case ExpenseCategory.grocery:
        return l10n.categoryGrocery;
      case ExpenseCategory.fuel:
        return l10n.categoryFuel;
      case ExpenseCategory.rent:
        return l10n.categoryRent;
      case ExpenseCategory.medical:
        return l10n.categoryMedical;
      case ExpenseCategory.shopping:
        return l10n.categoryShopping;
      case ExpenseCategory.travel:
        return l10n.categoryTravel;
      case ExpenseCategory.entertainment:
        return l10n.categoryEntertainment;
      case ExpenseCategory.education:
        return l10n.categoryEducation;
      case ExpenseCategory.utilities:
        return l10n.categoryUtilities;
      case ExpenseCategory.other:
        return l10n.categoryOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: ExpenseCategory.values.map((cat) {
        final isSelected = selected == cat;
        return GestureDetector(
          onTap: () => onSelected(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? cat.color.withAlpha(30) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? cat.color : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat.icon,
                  color: isSelected
                      ? cat.color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  _catLabel(cat, l10n),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? cat.color
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PaymentModeChips extends StatelessWidget {
  final PaymentMode selected;
  final ValueChanged<PaymentMode> onSelected;
  final AppLocalizations l10n;

  const _PaymentModeChips({
    required this.selected,
    required this.onSelected,
    required this.l10n,
  });

  String _modeLabel(PaymentMode mode, AppLocalizations l10n) {
    switch (mode) {
      case PaymentMode.cash:
        return l10n.paymentCash;
      case PaymentMode.upi:
        return l10n.paymentUpi;
      case PaymentMode.card:
        return l10n.paymentCard;
      case PaymentMode.netBanking:
        return l10n.paymentNetBanking;
      case PaymentMode.wallet:
        return l10n.paymentWallet;
      case PaymentMode.cheque:
        return l10n.paymentCheque;
      case PaymentMode.other:
        return l10n.paymentOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMode.values.map((mode) {
        final isSelected = selected == mode;
        return ChoiceChip(
          avatar: Icon(mode.icon, size: 16),
          label: Text(_modeLabel(mode, l10n)),
          selected: isSelected,
          onSelected: (_) => onSelected(mode),
          selectedColor: AppColors.primary.withAlpha(30),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : null,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

class _WalletDropdown extends ConsumerWidget {
  final String? selectedWalletId;
  final ValueChanged<String?> onChanged;
  final AppLocalizations l10n;

  const _WalletDropdown({
    required this.selectedWalletId,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    return walletsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('${l10n.error}: $e'),
      data: (wallets) {
        // Guard against stale selectedWalletId after load
        final validId =
            wallets.any((w) => w.id == selectedWalletId)
                ? selectedWalletId
                : (wallets.isNotEmpty ? wallets.first.id : null);

        return DropdownButtonFormField<String>(
          value: validId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: wallets
              .map((w) => DropdownMenuItem(
                    value: w.id,
                    child: Row(
                      children: [
                        Icon(w.type.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(w.name),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? l10n.required : null,
        );
      },
    );
  }
}

class _FolderDropdown extends ConsumerWidget {
  final String? selectedFolderId;
  final ValueChanged<String?> onChanged;

  const _FolderDropdown({
    required this.selectedFolderId,
    required this.onChanged,
  });

  List<Folder> _flatten(List<Folder> folders, [int depth = 0]) {
    final result = <Folder>[];
    for (final f in folders) {
      result.add(f);
      if (f.children.isNotEmpty) {
        result.addAll(_flatten(f.children, depth + 1));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);
    return foldersAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tree) {
        final flat = _flatten(tree);
        final validId = flat.any((f) => f.id == selectedFolderId)
            ? selectedFolderId
            : null;
        return DropdownButtonFormField<String?>(
          value: validId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.folder_rounded),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('None'),
            ),
            ...flat.map(
              (f) => DropdownMenuItem(
                value: f.id,
                child: Text(f.name),
              ),
            ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _TagInput extends StatelessWidget {
  final List<String> tags;
  final TextEditingController controller;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _TagInput({
    required this.tags,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: tags
                .map((tag) => Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => onRemove(tag),
                    ))
                .toList(),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Add tag…',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.tag_rounded),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              onPressed: () => onAdd(controller.text),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onSubmitted: onAdd,
        ),
      ],
    );
  }
}
