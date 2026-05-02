import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../data/wallet.dart';
import '../data/wallet_repository.dart';

class AddWalletScreen extends StatefulWidget {
  final Wallet? wallet;
  const AddWalletScreen({super.key, this.wallet});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  WalletType _selectedType = WalletType.cash;
  String _selectedColor = '#2563EB';
  bool _isSaving = false;

  static const _colors = [
    '#2563EB', '#16A34A', '#DC2626', '#D97706', '#7C3AED',
    '#DB2777', '#0891B2', '#65A30D', '#EA580C', '#4B5563',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.wallet != null) {
      _nameController.text = widget.wallet!.name;
      _balanceController.text =
          widget.wallet!.openingBalance.toStringAsFixed(2);
      _selectedType = widget.wallet!.type;
      _selectedColor = widget.wallet!.color ?? '#2563EB';
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
      final repo = WalletRepository();
      final now = DateTime.now().millisecondsSinceEpoch;
      final wallet = Wallet(
        id: widget.wallet?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        type: _selectedType,
        openingBalance:
            double.tryParse(_balanceController.text.trim()) ?? 0.0,
        color: _selectedColor,
        status: 'active',
        createdAt: widget.wallet?.createdAt ?? now,
        updatedAt: now,
      );
      if (widget.wallet == null) {
        await repo.createWallet(wallet);
      } else {
        await repo.updateWallet(wallet);
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.wallet != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Wallet' : l10n.walletAdd),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Wallet Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            Text('Type', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WalletType.values.map((type) {
                final selected = _selectedType == type;
                return ChoiceChip(
                  avatar: Icon(type.icon,
                      size: 18,
                      color: selected ? Colors.white : null),
                  label: Text(type.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Opening Balance',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
            const SizedBox(height: 20),
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((hex) {
                final color =
                    Color(int.parse(hex.replaceFirst('#', '0xFF')));
                final selected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: selected
                          ? [BoxShadow(color: color.withAlpha(128), blurRadius: 6)]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
