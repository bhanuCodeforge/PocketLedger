import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../data/wallet.dart';
import '../data/wallet_providers.dart';

class AddWalletScreen extends ConsumerStatefulWidget {
  final Wallet? wallet;

  const AddWalletScreen({super.key, this.wallet});

  @override
  ConsumerState<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends ConsumerState<AddWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  WalletType _selectedType = WalletType.cash;
  String _selectedColor = '#2563EB';
  bool _isSaving = false;

  static const _colors = [
    '#2563EB', // Blue
    '#16A34A', // Green
    '#DC2626', // Red
    '#D97706', // Amber
    '#7C3AED', // Violet
    '#DB2777', // Pink
    '#0891B2', // Cyan
    '#65A30D', // Lime
  ];

  bool get _isEditing => widget.wallet != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final w = widget.wallet!;
      _nameController.text = w.name;
      _balanceController.text = w.openingBalance == 0
          ? ''
          : w.openingBalance.toStringAsFixed(2);
      _selectedType = w.type;
      _selectedColor = w.color ?? '#2563EB';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(walletRepositoryProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final balance =
          double.tryParse(_balanceController.text.trim()) ?? 0.0;

      final wallet = Wallet(
        id: widget.wallet?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        type: _selectedType,
        openingBalance: balance,
        color: _selectedColor,
        isArchived: false,
        createdAt: widget.wallet?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        await repo.updateWallet(wallet);
      } else {
        await repo.createWallet(wallet);
      }

      ref.invalidate(walletsProvider);
      ref.invalidate(allWalletsProvider);
      if (wallet.id.isNotEmpty) {
        ref.invalidate(walletBalanceProvider(wallet.id));
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving wallet: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = ref.watch(currencyProvider);
    final symbol = currency['symbol'] ?? '₹';
    final accentColor = _parseColor(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.walletEdit : l10n.walletAdd),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.save,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Name ──────────────────────────────────────────────────
            _SectionLabel(label: 'Wallet Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. My Savings Account',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                prefixIcon: const Icon(Icons.label_outline),
                filled: true,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Wallet name is required';
                }
                if (v.trim().length > 40) {
                  return 'Name must be 40 characters or less';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Wallet Type ───────────────────────────────────────────
            _SectionLabel(label: l10n.walletType),
            const SizedBox(height: 10),
            _WalletTypeSelector(
              selected: _selectedType,
              accentColor: accentColor,
              onChanged: (t) => setState(() => _selectedType = t),
            ),

            const SizedBox(height: 24),

            // ── Opening Balance ───────────────────────────────────────
            _SectionLabel(label: l10n.walletOpeningBalance),
            const SizedBox(height: 8),
            TextFormField(
              controller: _balanceController,
              decoration: InputDecoration(
                hintText: '0.00',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                prefixText: '$symbol ',
                filled: true,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final val = double.tryParse(v.trim());
                if (val == null) return 'Enter a valid amount';
                if (val < 0) return 'Opening balance cannot be negative';
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Leave empty to start at 0.00',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 24),

            // ── Color ─────────────────────────────────────────────────
            _SectionLabel(label: 'Color'),
            const SizedBox(height: 10),
            _ColorPicker(
              colors: _colors,
              selected: _selectedColor,
              onChanged: (c) => setState(() => _selectedColor = c),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ─── Wallet Type Selector ────────────────────────────────────────────────────

class _WalletTypeSelector extends StatelessWidget {
  final WalletType selected;
  final Color accentColor;
  final ValueChanged<WalletType> onChanged;

  const _WalletTypeSelector({
    required this.selected,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WalletType.values.map((type) {
        final isSelected = selected == type;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withAlpha(25)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type.icon,
                  size: 18,
                  color: isSelected ? accentColor : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  type.label,
                  style: TextStyle(
                    color: isSelected ? accentColor : null,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
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

// ─── Color Picker ─────────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  final List<String> colors;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ColorPicker({
    required this.colors,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((hex) {
        Color color;
        try {
          color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
        } catch (_) {
          color = AppColors.primary;
        }
        final isSelected = selected == hex;
        return GestureDetector(
          onTap: () => onChanged(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: color.withAlpha(120),
                          blurRadius: 8,
                          spreadRadius: 1)
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 22)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
    );
  }
}
