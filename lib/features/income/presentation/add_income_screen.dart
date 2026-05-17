import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../../folders/data/folder.dart';
import '../../folders/data/folder_providers.dart';
import '../../wallets/data/wallet.dart';
import '../../wallets/data/wallet_providers.dart';
import '../data/income.dart';
import '../data/income_providers.dart';
import '../data/income_repository.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  /// When non-null the screen operates in edit mode, pre-filling from the
  /// existing record with this id.
  final String? editId;

  const AddIncomeScreen({super.key, this.editId});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  // ── Form state ────────────────────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  IncomeSource _source = IncomeSource.other;
  DateTime _incomeDate = DateTime.now();
  String? _walletId;
  String? _folderId;
  bool _isSaving = false;
  bool _isLoading = true; // true while loading edit record

  // Original record when editing
  Income? _original;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) {
      _loadExisting(widget.editId!);
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadExisting(String id) async {
    final repo = ref.read(incomeRepositoryProvider);
    final income = await repo.getById(id);
    if (!mounted) return;
    if (income != null) {
      _original = income;
      _amountController.text = income.amount.toStringAsFixed(2);
      _noteController.text = income.note;
      _source = income.source;
      _incomeDate = DateTime.fromMillisecondsSinceEpoch(income.incomeDate);
      _walletId = income.walletId;
      _folderId = income.folderId;
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_walletId == null) {
      _showError(AppLocalizations.of(context).required);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(incomeRepositoryProvider);
      final amount = double.parse(_amountController.text.trim());
      final now = DateTime.now().millisecondsSinceEpoch;

      if (_original == null) {
        // Create
        final draft = Income(
          id: '',
          walletId: _walletId!,
          folderId: _folderId,
          amount: amount,
          source: _source,
          note: _noteController.text.trim(),
          incomeDate: _incomeDate.millisecondsSinceEpoch,
          isRecurring: false,
          createdAt: now,
          updatedAt: now,
        );
        await repo.create(draft);
      } else {
        // Update
        final updated = _original!.copyWith(
          walletId: _walletId!,
          folderId: _folderId,
          amount: amount,
          source: _source,
          note: _noteController.text.trim(),
          incomeDate: _incomeDate.millisecondsSinceEpoch,
          updatedAt: now,
        );
        await repo.update(updated);
      }

      // Refresh list + totals
      ref.invalidate(incomeListProvider);
      ref.invalidate(todayIncomeTotalProvider);
      ref.invalidate(currentMonthIncomeTotalProvider);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.expense,
      ),
    );
  }

  // ── Date picker ───────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incomeDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _incomeDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _incomeDate.hour,
            _incomeDate.minute,
          ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.editId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.incomeEdit : l10n.incomeAdd),
        actions: [
          TextButton(
            onPressed: (_isSaving || _isLoading) ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.save,
                    style: const TextStyle(color: AppColors.income),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _AmountField(
                    controller: _amountController,
                    currencySymbol:
                        ref.watch(currencyProvider)['symbol'] ?? '₹',
                  ),
                  const SizedBox(height: 24),
                  _SourcePicker(
                    selected: _source,
                    l10n: l10n,
                    onChanged: (s) => setState(() => _source = s),
                  ),
                  const SizedBox(height: 24),
                  _WalletDropdown(
                    selectedId: _walletId,
                    l10n: l10n,
                    onChanged: (id) => setState(() => _walletId = id),
                  ),
                  const SizedBox(height: 20),
                  _FolderDropdown(
                    selectedId: _folderId,
                    l10n: l10n,
                    onChanged: (id) => setState(() => _folderId = id),
                  ),
                  const SizedBox(height: 20),
                  _DateRow(
                    date: _incomeDate,
                    l10n: l10n,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 20),
                  _NoteField(
                    controller: _noteController,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// ── Amount field ──────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String currencySymbol;

  const _AmountField({
    required this.controller,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.incomeLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.income,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                currencySymbol,
                style: AppTextStyles.amountLarge.copyWith(
                  color: AppColors.income,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  style: AppTextStyles.amountLarge.copyWith(
                    color: AppColors.income,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: AppTextStyles.amountLarge.copyWith(
                      color: AppColors.income.withValues(alpha: 0.4),
                    ),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid amount greater than 0';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Source picker (chips) ─────────────────────────────────────────────────────

class _SourcePicker extends StatelessWidget {
  final IncomeSource selected;
  final AppLocalizations l10n;
  final ValueChanged<IncomeSource> onChanged;

  const _SourcePicker({
    required this.selected,
    required this.l10n,
    required this.onChanged,
  });

  String _label(IncomeSource s) {
    switch (s) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.incomeSource, style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: IncomeSource.values.map((source) {
            final isSelected = source == selected;
            return FilterChip(
              avatar: Icon(
                source.icon,
                size: 17,
                color: isSelected ? Colors.white : AppColors.income,
              ),
              label: Text(_label(source)),
              selected: isSelected,
              onSelected: (_) => onChanged(source),
              selectedColor: AppColors.income,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              checkmarkColor: Colors.white,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected ? AppColors.income : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Wallet dropdown ───────────────────────────────────────────────────────────

class _WalletDropdown extends ConsumerWidget {
  final String? selectedId;
  final AppLocalizations l10n;
  final ValueChanged<String?> onChanged;

  const _WalletDropdown({
    required this.selectedId,
    required this.l10n,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);

    return walletsAsync.when(
      loading: () => const _DropdownSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (wallets) {
        // Auto-select if only one wallet and nothing selected yet
        if (wallets.length == 1 && selectedId == null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => onChanged(wallets.first.id),
          );
        }

        return DropdownButtonFormField<String>(
          value: selectedId,
          decoration: InputDecoration(
            labelText: 'Wallet *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: wallets
              .map((w) => DropdownMenuItem<String>(
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

// ── Folder dropdown ───────────────────────────────────────────────────────────

class _FolderDropdown extends ConsumerWidget {
  final String? selectedId;
  final AppLocalizations l10n;
  final ValueChanged<String?> onChanged;

  const _FolderDropdown({
    required this.selectedId,
    required this.l10n,
    required this.onChanged,
  });

  /// Flatten a folder tree into a flat list with indentation level.
  List<({Folder folder, int depth})> _flatten(
      List<Folder> nodes, int depth) {
    final result = <({Folder folder, int depth})>[];
    for (final n in nodes) {
      result.add((folder: n, depth: depth));
      if (n.children.isNotEmpty) {
        result.addAll(_flatten(n.children, depth + 1));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);

    return foldersAsync.when(
      loading: () => const _DropdownSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (folders) {
        final flat = _flatten(folders, 0);
        if (flat.isEmpty) return const SizedBox.shrink();

        return DropdownButtonFormField<String?>(
          value: selectedId,
          decoration: const InputDecoration(
            labelText: 'Folder (optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.folder_outlined),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('None'),
            ),
            ...flat.map((entry) => DropdownMenuItem<String?>(
                  value: entry.folder.id,
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: (entry.depth * 16).toDouble()),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(entry.folder.name),
                      ],
                    ),
                  ),
                )),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

// ── Date row ──────────────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  final DateTime date;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _DateRow({
    required this.date,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today_outlined),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('EEE, dd MMM yyyy').format(date),
              style: AppTextStyles.bodyMedium.copyWith(
                color: scheme.onSurface,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Note field ────────────────────────────────────────────────────────────────

class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  final AppLocalizations l10n;

  const _NoteField({required this.controller, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: l10n.note,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.notes_outlined),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      maxLines: 3,
      maxLength: 250,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

// ── Skeleton placeholder for async dropdowns ──────────────────────────────────

class _DropdownSkeleton extends StatelessWidget {
  const _DropdownSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56,
      child: Center(child: LinearProgressIndicator()),
    );
  }
}
