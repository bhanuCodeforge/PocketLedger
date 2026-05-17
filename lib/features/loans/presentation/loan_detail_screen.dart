import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../data/loan.dart';
import '../data/loan_payment.dart';
import '../data/loan_providers.dart';
import '../data/loan_repository.dart';

class LoanDetailScreen extends ConsumerWidget {
  final String id;
  const LoanDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currency = ref.watch(currencyProvider);
    final symbol = currency['symbol'] ?? '₹';

    // Watch providers that depend on this loan.
    final paymentsAsync = ref.watch(loanPaymentsProvider(id));
    final totalPaidAsync = ref.watch(loanTotalPaidProvider(id));

    return FutureBuilder<Loan?>(
      future: LoanRepository().getById(id),
      builder: (context, snap) {
        if (!snap.hasData && !snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final loan = snap.data;
        if (loan == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.noData)),
          );
        }
        return _LoanDetailView(
          loan: loan,
          symbol: symbol,
          paymentsAsync: paymentsAsync,
          totalPaidAsync: totalPaidAsync,
          onRefresh: () {
            ref.invalidate(loanPaymentsProvider(id));
            ref.invalidate(loanTotalPaidProvider(id));
            ref.invalidate(activeLoansProvider);
            ref.invalidate(settledLoansProvider);
          },
        );
      },
    );
  }
}

// ── Main detail view ──────────────────────────────────────────────────────────

class _LoanDetailView extends StatefulWidget {
  final Loan loan;
  final String symbol;
  final AsyncValue<List<LoanPayment>> paymentsAsync;
  final AsyncValue<double> totalPaidAsync;
  final VoidCallback onRefresh;

  const _LoanDetailView({
    required this.loan,
    required this.symbol,
    required this.paymentsAsync,
    required this.totalPaidAsync,
    required this.onRefresh,
  });

  @override
  State<_LoanDetailView> createState() => _LoanDetailViewState();
}

class _LoanDetailViewState extends State<_LoanDetailView> {
  late Loan _loan;

  @override
  void initState() {
    super.initState();
    _loan = widget.loan;
  }

  @override
  void didUpdateWidget(_LoanDetailView old) {
    super.didUpdateWidget(old);
    if (old.loan.id != widget.loan.id) _loan = widget.loan;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _settle(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.loanSettle),
        content: Text(l10n.loanSettleConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.loanSettle),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await LoanRepository().settle(_loan.id);
    final updated = await LoanRepository().getById(_loan.id);
    if (mounted && updated != null) {
      setState(() => _loan = updated);
      widget.onRefresh();
    }
  }

  Future<void> _delete(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: const Text('Delete this loan? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await LoanRepository().delete(_loan.id);
    if (mounted) {
      widget.onRefresh();
      context.pop();
    }
  }

  Future<void> _addPayment(AppLocalizations l10n) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _AddPaymentDialog(
        loanId: _loan.id,
        symbol: widget.symbol,
        onAdded: () {
          widget.onRefresh();
          // Reload loan to pick up updated_at change.
          LoanRepository().getById(_loan.id).then((updated) {
            if (mounted && updated != null) {
              setState(() => _loan = updated);
            }
          });
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final due = _loan.totalDue(now);
    final interest = _loan.totalInterest(now);
    final isGiven = _loan.type == LoanType.given;
    final typeColor = isGiven ? AppColors.income : AppColors.expense;

    return Scaffold(
      appBar: AppBar(
        title: Text(_loan.contactName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.delete,
            onPressed: () => _delete(l10n),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Overdue banner ───────────────────────────────────────────────
            if (_loan.isOverdue) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.expense.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.expense.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.expense),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.loanOverdue,
                        style: const TextStyle(
                            color: AppColors.expense,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Summary card ─────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type + settle badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: typeColor.withAlpha(80)),
                          ),
                          child: Text(
                            isGiven
                                ? l10n.loanGiven
                                : l10n.loanTaken,
                            style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (_loan.isSettled) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.income.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Settled',
                              style: TextStyle(
                                  color: AppColors.income,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (_loan.settledAt != null)
                          Text(
                            'Settled ${_formatDate(DateTime.fromMillisecondsSinceEpoch(_loan.settledAt!))}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Amounts grid
                    _AmountRow(
                      label: 'Principal',
                      value:
                          '${widget.symbol}${_loan.principalAmount.toStringAsFixed(2)}',
                    ),
                    if (_loan.interestType != InterestType.none &&
                        _loan.interestRate > 0) ...[
                      _AmountRow(
                        label: 'Interest (${_loan.interestRate}% '
                            '${_loan.interestType == InterestType.simple ? "Simple" : "Compound"})',
                        value:
                            '${widget.symbol}${interest.toStringAsFixed(2)}',
                      ),
                    ],
                    const Divider(height: 20),
                    _AmountRow(
                      label: l10n.loanTotalDue,
                      value:
                          '${widget.symbol}${due.toStringAsFixed(2)}',
                      bold: true,
                      color: typeColor,
                    ),

                    // Paid / remaining (from payments provider)
                    widget.totalPaidAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (paid) {
                        final remaining = (due - paid).clamp(0, double.infinity);
                        final progress =
                            due > 0 ? (paid / due).clamp(0.0, 1.0) : 0.0;
                        return Column(
                          children: [
                            _AmountRow(
                              label: l10n.loanPaidAmount,
                              value:
                                  '${widget.symbol}${paid.toStringAsFixed(2)}',
                              color: AppColors.income,
                            ),
                            _AmountRow(
                              label: l10n.loanRemainingAmount,
                              value:
                                  '${widget.symbol}${remaining.toStringAsFixed(2)}',
                              color: remaining > 0
                                  ? AppColors.expense
                                  : AppColors.income,
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor:
                                    Colors.grey.withAlpha(40),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  progress >= 1.0
                                      ? AppColors.income
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(progress * 100).toStringAsFixed(1)}% paid',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Details card ─────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Details',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Start Date',
                      value: _formatDate(DateTime.fromMillisecondsSinceEpoch(
                          _loan.startDate)),
                    ),
                    if (_loan.dueDate != null)
                      _DetailRow(
                        icon: Icons.event_outlined,
                        label: 'Due Date',
                        value: _formatDate(
                            DateTime.fromMillisecondsSinceEpoch(
                                _loan.dueDate!)),
                        valueColor:
                            _loan.isOverdue ? AppColors.expense : null,
                      ),
                    if (_loan.interestType != InterestType.none) ...[
                      _DetailRow(
                        icon: Icons.percent,
                        label: 'Interest',
                        value:
                            '${_loan.interestRate}% ${_loan.interestType == InterestType.compound ? "(${_loan.compoundFrequency.value})" : ""}',
                      ),
                    ],
                    if (_loan.note.isNotEmpty)
                      _DetailRow(
                        icon: Icons.notes_outlined,
                        label: 'Note',
                        value: _loan.note,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Payment history ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payment History',
                    style: Theme.of(context).textTheme.titleMedium),
                if (!_loan.isSettled)
                  TextButton.icon(
                    onPressed: () => _addPayment(l10n),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Payment'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            widget.paymentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (payments) {
                if (payments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Text(l10n.noData,
                        style: const TextStyle(color: Colors.grey)),
                  );
                }
                return Column(
                  children: payments
                      .map((p) => _PaymentTile(
                            payment: p,
                            symbol: widget.symbol,
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),

      // ── Bottom action bar ──────────────────────────────────────────────────
      bottomNavigationBar: _loan.isSettled
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addPayment(l10n),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Add Payment'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _settle(l10n),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(l10n.loanSettle),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.income,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_monthAbbr(dt.month)} ${dt.year}';

  String _monthAbbr(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _AmountRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: bold
                      ? Theme.of(context).textTheme.bodyMedium?.color
                      : Colors.grey,
                )),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PaymentTile extends StatelessWidget {
  final LoanPayment payment;
  final String symbol;

  const _PaymentTile({required this.payment, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(payment.paymentDate);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.income.withAlpha(25),
          child: const Icon(Icons.payments_outlined,
              color: AppColors.income, size: 20),
        ),
        title: Text(
          '$symbol${payment.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.income,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${date.day} ${_monthAbbr(date.month)} ${date.year}',
                style: const TextStyle(fontSize: 12)),
            if (payment.note.isNotEmpty)
              Text(payment.note,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        isThreeLine: payment.note.isNotEmpty,
      ),
    );
  }

  String _monthAbbr(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}

// ── Add payment dialog ────────────────────────────────────────────────────────

class _AddPaymentDialog extends StatefulWidget {
  final String loanId;
  final String symbol;
  final VoidCallback onAdded;

  const _AddPaymentDialog({
    required this.loanId,
    required this.symbol,
    required this.onAdded,
  });

  @override
  State<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<_AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final payment = LoanPayment(
        id: const Uuid().v4(),
        loanId: widget.loanId,
        amount: double.parse(_amountController.text.trim()),
        note: _noteController.text.trim(),
        paymentDate: _paymentDate.millisecondsSinceEpoch,
        createdAt: now,
      );
      await LoanRepository().addPayment(payment);
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = _paymentDate;
    final dateStr =
        '${date.day} ${_monthAbbr(date.month)} ${date.year}';

    return AlertDialog(
      title: const Text('Add Payment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount *',
                border: const OutlineInputBorder(),
                prefixText: '${widget.symbol} ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payment Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(dateStr),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  String _monthAbbr(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}
