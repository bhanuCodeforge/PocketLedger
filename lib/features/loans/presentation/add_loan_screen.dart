import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../../contacts/data/contact.dart';
import '../../contacts/data/contact_providers.dart';
import '../../wallets/data/wallet.dart';
import '../../wallets/data/wallet_providers.dart';
import '../data/loan.dart';
import '../data/loan_repository.dart';

class AddLoanScreen extends ConsumerStatefulWidget {
  const AddLoanScreen({super.key});

  @override
  ConsumerState<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends ConsumerState<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _rateController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  final _contactNameController = TextEditingController();

  LoanType _type = LoanType.given;
  InterestType _interestType = InterestType.none;
  CompoundFrequency _compoundFrequency = CompoundFrequency.monthly;
  DateTime _startDate = DateTime.now();
  DateTime? _dueDate;
  Contact? _selectedContact;
  Wallet? _selectedWallet;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    _noteController.dispose();
    _contactNameController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickContact(List<Contact> contacts) async {
    final result = await showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ContactPickerSheet(contacts: contacts),
    );
    if (result != null) {
      setState(() {
        _selectedContact = result;
        _contactNameController.text = result.name;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = LoanRepository();
      final now = DateTime.now().millisecondsSinceEpoch;
      final loan = Loan(
        id: const Uuid().v4(),
        contactId: _selectedContact?.id,
        contactName: _contactNameController.text.trim(),
        type: _type,
        principalAmount:
            double.tryParse(_amountController.text.trim()) ?? 0.0,
        interestRate: double.tryParse(_rateController.text.trim()) ?? 0.0,
        interestType: _interestType,
        compoundFrequency: _compoundFrequency,
        startDate: _startDate.millisecondsSinceEpoch,
        dueDate: _dueDate?.millisecondsSinceEpoch,
        note: _noteController.text.trim(),
        walletId: _selectedWallet?.id,
        createdAt: now,
        updatedAt: now,
      );
      await repo.create(loan);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contactsAsync = ref.watch(contactsProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final currency = ref.watch(currencyProvider);
    final symbol = currency['symbol'] ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loanAdd),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
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
          padding: const EdgeInsets.all(16),
          children: [
            // ── Loan type toggle ────────────────────────────────────────────
            _SectionLabel('Loan Type'),
            const SizedBox(height: 8),
            SegmentedButton<LoanType>(
              segments: [
                ButtonSegment(
                  value: LoanType.given,
                  label: Text(l10n.loanGiven),
                  icon: const Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: LoanType.taken,
                  label: Text(l10n.loanTaken),
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 20),

            // ── Contact ─────────────────────────────────────────────────────
            _SectionLabel('Contact'),
            const SizedBox(height: 8),
            contactsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (contacts) => TextFormField(
                controller: _contactNameController,
                decoration: InputDecoration(
                  labelText: 'Contact Name *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: contacts.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.contacts_outlined),
                          onPressed: () => _pickContact(contacts),
                          tooltip: 'Pick from contacts',
                        )
                      : null,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.required : null,
                onChanged: (v) {
                  // Deselect linked contact if name changed manually
                  if (_selectedContact != null &&
                      v.trim() != _selectedContact!.name) {
                    setState(() => _selectedContact = null);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Principal amount ────────────────────────────────────────────
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: '${l10n.loanAmount} *',
                border: const OutlineInputBorder(),
                prefixIcon: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Text(symbol,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.required;
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return l10n.errorInvalidAmount;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Interest rate ───────────────────────────────────────────────
            TextFormField(
              controller: _rateController,
              decoration: InputDecoration(
                labelText: l10n.loanInterestRate,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.percent),
                helperText: 'Set to 0 for no interest',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: (v) {
                final rate = double.tryParse(v) ?? 0;
                if (rate == 0) {
                  setState(() => _interestType = InterestType.none);
                } else if (_interestType == InterestType.none) {
                  setState(() => _interestType = InterestType.simple);
                }
              },
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v);
                if (n == null || n < 0) return 'Enter a valid rate';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Interest type ───────────────────────────────────────────────
            if ((double.tryParse(_rateController.text) ?? 0) > 0) ...[
              _SectionLabel(l10n.loanInterestType),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.loanSimple),
                    selected: _interestType == InterestType.simple,
                    onSelected: (_) =>
                        setState(() => _interestType = InterestType.simple),
                  ),
                  ChoiceChip(
                    label: Text(l10n.loanCompound),
                    selected: _interestType == InterestType.compound,
                    onSelected: (_) =>
                        setState(() => _interestType = InterestType.compound),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Compound frequency ──────────────────────────────────────────
            if (_interestType == InterestType.compound) ...[
              _SectionLabel('Compound Frequency'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: CompoundFrequency.values.map((f) {
                  final labels = {
                    CompoundFrequency.monthly: 'Monthly',
                    CompoundFrequency.quarterly: 'Quarterly',
                    CompoundFrequency.yearly: 'Yearly',
                  };
                  return ChoiceChip(
                    label: Text(labels[f]!),
                    selected: _compoundFrequency == f,
                    onSelected: (_) =>
                        setState(() => _compoundFrequency = f),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // ── Start date ──────────────────────────────────────────────────
            _DatePickerField(
              label: 'Start Date *',
              date: _startDate,
              onTap: _pickStartDate,
            ),
            const SizedBox(height: 16),

            // ── Due date ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: l10n.loanDueDate,
                    date: _dueDate,
                    onTap: _pickDueDate,
                    optional: true,
                  ),
                ),
                if (_dueDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _dueDate = null),
                    tooltip: 'Clear due date',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Wallet ──────────────────────────────────────────────────────
            walletsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (wallets) {
                if (wallets.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<Wallet?>(
                  value: _selectedWallet,
                  decoration: const InputDecoration(
                    labelText: 'Linked Wallet (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('None')),
                    ...wallets.map((w) => DropdownMenuItem(
                          value: w,
                          child: Text(w.name),
                        )),
                  ],
                  onChanged: (w) => setState(() => _selectedWallet = w),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Note ────────────────────────────────────────────────────────
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: '${l10n.note} (optional)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 40),

            // ── Live interest preview ───────────────────────────────────────
            _InterestPreview(
              principal:
                  double.tryParse(_amountController.text.trim()) ?? 0,
              rate: double.tryParse(_rateController.text.trim()) ?? 0,
              interestType: _interestType,
              compoundFrequency: _compoundFrequency,
              startDate: _startDate,
              dueDate: _dueDate,
              symbol: symbol,
            ),
            const SizedBox(height: 40),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelLarge);
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool optional;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = date != null
        ? '${date!.day} ${_monthAbbr(date!.month)} ${date!.year}'
        : optional
            ? 'Not set'
            : '';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: date == null ? Colors.grey : null,
          ),
        ),
      ),
    );
  }

  String _monthAbbr(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}

class _InterestPreview extends StatelessWidget {
  final double principal;
  final double rate;
  final InterestType interestType;
  final CompoundFrequency compoundFrequency;
  final DateTime startDate;
  final DateTime? dueDate;
  final String symbol;

  const _InterestPreview({
    required this.principal,
    required this.rate,
    required this.interestType,
    required this.compoundFrequency,
    required this.startDate,
    required this.dueDate,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    if (principal <= 0 ||
        rate <= 0 ||
        interestType == InterestType.none) {
      return const SizedBox.shrink();
    }

    final asOf = dueDate ?? DateTime.now().add(const Duration(days: 365));
    final tempLoan = Loan(
      id: '',
      contactName: '',
      type: LoanType.given,
      principalAmount: principal,
      interestRate: rate,
      interestType: interestType,
      compoundFrequency: compoundFrequency,
      startDate: startDate.millisecondsSinceEpoch,
      dueDate: asOf.millisecondsSinceEpoch,
      createdAt: 0,
      updatedAt: 0,
    );

    final interest = tempLoan.totalInterest(asOf);
    final total = tempLoan.totalDue(asOf);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interest Preview',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontSize: 13)),
          const SizedBox(height: 8),
          _row(context, 'Principal:', '$symbol${principal.toStringAsFixed(2)}'),
          _row(context, 'Interest:', '$symbol${interest.toStringAsFixed(2)}'),
          const Divider(height: 16),
          _row(context, 'Total Due:', '$symbol${total.toStringAsFixed(2)}',
              bold: true),
          if (dueDate == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '* Calculated for 1 year. Set a due date for exact figure.',
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );
}

// ── Contact picker bottom sheet ───────────────────────────────────────────────

class _ContactPickerSheet extends StatefulWidget {
  final List<Contact> contacts;
  const _ContactPickerSheet({required this.contacts});

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.contacts
        : widget.contacts
            .where((c) =>
                c.name.toLowerCase().contains(_query.toLowerCase()) ||
                (c.phone ?? '').contains(_query))
            .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search contacts…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final c = filtered[i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(c.initials,
                        style: const TextStyle(fontSize: 14)),
                  ),
                  title: Text(c.name),
                  subtitle:
                      c.phone != null ? Text(c.phone!) : null,
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
