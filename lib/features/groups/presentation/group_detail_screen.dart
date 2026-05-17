import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../data/group.dart';
import '../data/group_providers.dart';
import '../data/group_repository.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _invalidateAll() {
    ref.invalidate(groupByIdProvider(widget.groupId));
    ref.invalidate(groupMembersProvider(widget.groupId));
    ref.invalidate(groupTransactionsProvider(widget.groupId));
    ref.invalidate(groupBalanceProvider(widget.groupId));
    ref.invalidate(groupTotalProvider(widget.groupId));
    ref.invalidate(groupsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groupAsync = ref.watch(groupByIdProvider(widget.groupId));

    final group = groupAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(group?.name ?? '…'),
        centerTitle: false,
        actions: [
          if (group != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit group',
              onPressed: () async {
                await context.push('/groups/add', extra: group);
                _invalidateAll();
                ref.invalidate(groupByIdProvider(widget.groupId));
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Expenses'),
            Tab(text: 'Settle Up'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final members = await ref
              .read(groupRepositoryProvider)
              .getMembers(widget.groupId);
          if (!mounted) return;
          if (members.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Add at least one member before recording an expense.'),
            ));
            return;
          }
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => _AddTransactionSheet(
              groupId: widget.groupId,
              members: members,
              onSaved: _invalidateAll,
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.groupSplit),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _MembersTab(groupId: widget.groupId, onChanged: _invalidateAll),
          _ExpensesTab(groupId: widget.groupId),
          _SettleUpTab(groupId: widget.groupId, onSettled: _invalidateAll),
        ],
      ),
    );
  }
}

// ── Members tab ───────────────────────────────────────────────────────────────

class _MembersTab extends ConsumerWidget {
  final String groupId;
  final VoidCallback onChanged;

  const _MembersTab({required this.groupId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final balanceAsync = ref.watch(groupBalanceProvider(groupId));

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (members) {
        final balances = balanceAsync.valueOrNull ?? {};
        return Column(
          children: [
            Expanded(
              child: members.isEmpty
                  ? _centeredHint('No members yet. Add people to split expenses.')
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final m = members[i];
                        final net = balances[m.id] ?? 0.0;
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          leading: _MemberAvatar(member: m),
                          title: Text(
                            m.isSelf ? '${m.name} (You)' : m.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: net.abs() < 0.01
                              ? Text('Settled up',
                                  style: TextStyle(
                                      color: AppColors.income, fontSize: 12))
                              : net > 0
                                  ? Text(
                                      'Gets back ₹${net.abs().toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: AppColors.income, fontSize: 12),
                                    )
                                  : Text(
                                      'Owes ₹${net.abs().toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: AppColors.expense, fontSize: 12),
                                    ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.expense),
                            tooltip: 'Remove member',
                            onPressed: () async {
                              await GroupRepository().removeMember(m.id);
                              onChanged();
                            },
                          ),
                        );
                      },
                    ),
            ),
            // Add member button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => _AddMemberSheet(
                      groupId: groupId,
                      existingNames: members.map((m) => m.name).toSet(),
                      onAdded: onChanged,
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add Member'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Expenses tab ──────────────────────────────────────────────────────────────

class _ExpensesTab extends ConsumerWidget {
  final String groupId;
  const _ExpensesTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(groupTransactionsProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return txAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (transactions) {
        if (transactions.isEmpty) {
          return _centeredHint('No expenses recorded yet.\nTap + to add a split expense.');
        }
        final memberMap = {
          for (final m in membersAsync.valueOrNull ?? <GroupMember>[]) m.id: m,
        };
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final tx = transactions[i];
            final payer = memberMap[tx.paidByMemberId];
            final date = DateTime.fromMillisecondsSinceEpoch(tx.transactionDate);
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryContainer,
                child: Icon(
                  _categoryIcon(tx.category),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(tx.description,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paid by ${payer?.name ?? 'Unknown'}  •  ${_fmtDate(date)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    tx.splitType.value == 'equal'
                        ? 'Split equally'
                        : tx.splitType.value == 'custom'
                            ? 'Custom split'
                            : 'By percentage',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              trailing: Text(
                '₹${tx.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.expense,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  IconData _categoryIcon(String cat) {
    const map = {
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
    };
    return map[cat] ?? Icons.receipt_outlined;
  }
}

// ── Settle Up tab ─────────────────────────────────────────────────────────────

class _SettleUpTab extends ConsumerWidget {
  final String groupId;
  final VoidCallback onSettled;

  const _SettleUpTab({required this.groupId, required this.onSettled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final balanceAsync = ref.watch(groupBalanceProvider(groupId));

    return balanceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (balance) {
        final members = membersAsync.valueOrNull ?? [];
        final memberMap = {for (final m in members) m.id: m};

        // Compute minimal-transfer settlement plan.
        final settlements = _computeSettlements(balance, memberMap);

        if (settlements.isEmpty) {
          return _centeredHint('All settled up! Everyone is even.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Who owes whom',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: settlements.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = settlements[i];
                  return _SettlementTile(
                    fromName: s.fromName,
                    toName: s.toName,
                    amount: s.amount,
                    onSettle: () async {
                      // Mark all unsettled splits from debtor to creditor as settled.
                      final repo = ref.read(groupRepositoryProvider);
                      final debts = await repo.getUnsettledDebts(groupId);
                      for (final d in debts) {
                        if (d['debtor_member_id'] == s.fromId &&
                            d['creditor_member_id'] == s.toId) {
                          await repo.settleSplit(d['split_id'] as String);
                        }
                      }
                      onSettled();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Greedy minimal-transfer algorithm.
  List<_Settlement> _computeSettlements(
      Map<String, double> balance, Map<String, GroupMember> members) {
    // Build positive (creditors) and negative (debtors) lists.
    final creditors = <String, double>{};
    final debtors = <String, double>{};

    for (final e in balance.entries) {
      if (e.value > 0.01) creditors[e.key] = e.value;
      if (e.value < -0.01) debtors[e.key] = e.value.abs();
    }

    final result = <_Settlement>[];
    final credList = creditors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final debList = debtors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final credAmounts = {for (final e in credList) e.key: e.value};
    final debAmounts = {for (final e in debList) e.key: e.value};

    for (final debEntry in debList) {
      var remaining = debAmounts[debEntry.key]!;
      for (final credEntry in credList) {
        if (remaining < 0.01) break;
        final credRemaining = credAmounts[credEntry.key] ?? 0;
        if (credRemaining < 0.01) continue;
        final transfer = remaining < credRemaining ? remaining : credRemaining;
        result.add(_Settlement(
          fromId: debEntry.key,
          fromName: members[debEntry.key]?.name ?? 'Unknown',
          toId: credEntry.key,
          toName: members[credEntry.key]?.name ?? 'Unknown',
          amount: transfer,
        ));
        credAmounts[credEntry.key] = credRemaining - transfer;
        remaining -= transfer;
      }
    }
    return result;
  }
}

class _Settlement {
  final String fromId, fromName, toId, toName;
  final double amount;
  const _Settlement({
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
  });
}

class _SettlementTile extends StatelessWidget {
  final String fromName;
  final String toName;
  final double amount;
  final VoidCallback onSettle;

  const _SettlementTile({
    required this.fromName,
    required this.toName,
    required this.amount,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: const CircleAvatar(
        backgroundColor: AppColors.warningLight,
        child: Icon(Icons.arrow_forward, color: AppColors.warning, size: 20),
      ),
      title: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
                text: fromName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const TextSpan(text: ' owes '),
            TextSpan(
                text: toName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      subtitle: Text(
        '₹${amount.toStringAsFixed(2)}',
        style: const TextStyle(
            color: AppColors.expense, fontWeight: FontWeight.bold),
      ),
      trailing: TextButton.icon(
        onPressed: onSettle,
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text('Settle'),
        style: TextButton.styleFrom(foregroundColor: AppColors.income),
      ),
    );
  }
}

// ── Add Member bottom sheet ───────────────────────────────────────────────────

class _AddMemberSheet extends StatefulWidget {
  final String groupId;
  final Set<String> existingNames;
  final VoidCallback onAdded;

  const _AddMemberSheet({
    required this.groupId,
    required this.existingNames,
    required this.onAdded,
  });

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _isSelf = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final member = GroupMember(
        id: '',
        groupId: widget.groupId,
        name: _nameCtrl.text.trim(),
        isSelf: _isSelf,
        createdAt: now,
      );
      await GroupRepository().addMember(member);
      widget.onAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Member',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Member Name',
                prefixIcon: const Icon(Icons.person_outline),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (widget.existingNames.contains(v.trim())) {
                  return 'A member with this name already exists';
                }
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _isSelf,
              onChanged: (v) => setState(() => _isSelf = v ?? false),
              title: const Text('This is me (the app user)'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Add Member'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Transaction bottom sheet ──────────────────────────────────────────────

class _AddTransactionSheet extends StatefulWidget {
  final String groupId;
  final List<GroupMember> members;
  final VoidCallback onSaved;

  const _AddTransactionSheet({
    required this.groupId,
    required this.members,
    required this.onSaved,
  });

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _category = 'other';
  SplitType _splitType = SplitType.equal;
  String? _paidByMemberId;
  DateTime _txDate = DateTime.now();
  bool _saving = false;

  // Custom split: memberId → amount controller
  Map<String, TextEditingController> _customAmountCtrls = {};

  static const _categories = [
    'food', 'grocery', 'fuel', 'rent', 'medical',
    'shopping', 'travel', 'entertainment', 'education', 'utilities', 'other',
  ];

  @override
  void initState() {
    super.initState();
    _paidByMemberId = widget.members.first.id;
    _initCustomCtrls();
  }

  void _initCustomCtrls() {
    for (final ctrl in _customAmountCtrls.values) {
      ctrl.dispose();
    }
    _customAmountCtrls = {
      for (final m in widget.members)
        m.id: TextEditingController(),
    };
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    for (final c in _customAmountCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _txDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _txDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final totalAmount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    // Validate custom splits sum to total.
    if (_splitType == SplitType.custom || _splitType == SplitType.percentage) {
      double sum = 0;
      for (final ctrl in _customAmountCtrls.values) {
        sum += double.tryParse(ctrl.text.trim()) ?? 0;
      }
      if (_splitType == SplitType.custom && (sum - totalAmount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Custom split amounts must sum to ₹${totalAmount.toStringAsFixed(2)}')),
        );
        return;
      }
      if (_splitType == SplitType.percentage && (sum - 100).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Percentages must sum to 100%')),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final repo = GroupRepository();
      final now = DateTime.now().millisecondsSinceEpoch;

      final tx = GroupTransaction(
        id: '',
        groupId: widget.groupId,
        paidByMemberId: _paidByMemberId!,
        description: _descCtrl.text.trim(),
        amount: totalAmount,
        category: _category,
        splitType: _splitType,
        transactionDate: _txDate.millisecondsSinceEpoch,
        note: _noteCtrl.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      final txId = await repo.createTransaction(tx);

      // Create splits.
      final count = widget.members.length;
      for (final member in widget.members) {
        double splitAmount;
        if (_splitType == SplitType.equal) {
          splitAmount = totalAmount / count;
        } else if (_splitType == SplitType.custom) {
          splitAmount =
              double.tryParse(_customAmountCtrls[member.id]!.text.trim()) ?? 0;
        } else {
          // percentage
          final pct =
              double.tryParse(_customAmountCtrls[member.id]!.text.trim()) ?? 0;
          splitAmount = totalAmount * pct / 100;
        }
        await repo.createSplit(GroupTransactionSplit(
          id: '',
          transactionId: txId,
          memberId: member.id,
          amount: splitAmount,
          isSettled: member.id == _paidByMemberId,
          settledAt: member.id == _paidByMemberId ? now : null,
        ));
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Split Expense',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Description
              TextFormField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Total Amount',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  final a = double.tryParse(v?.trim() ?? '');
                  if (a == null || a <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(_catLabel(c)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),

              // Paid by
              DropdownButtonFormField<String>(
                value: _paidByMemberId,
                decoration: InputDecoration(
                  labelText: 'Paid by',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: widget.members
                    .map((m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.isSelf ? '${m.name} (You)' : m.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _paidByMemberId = v),
              ),
              const SizedBox(height: 12),

              // Date
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    '${_txDate.day.toString().padLeft(2, '0')}/'
                    '${_txDate.month.toString().padLeft(2, '0')}/'
                    '${_txDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Split type
              Text(
                'Split Type',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<SplitType>(
                segments: const [
                  ButtonSegment(
                    value: SplitType.equal,
                    label: Text('Equal'),
                    icon: Icon(Icons.balance, size: 16),
                  ),
                  ButtonSegment(
                    value: SplitType.custom,
                    label: Text('Custom'),
                    icon: Icon(Icons.edit_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: SplitType.percentage,
                    label: Text('%'),
                    icon: Icon(Icons.percent, size: 16),
                  ),
                ],
                selected: {_splitType},
                onSelectionChanged: (s) =>
                    setState(() => _splitType = s.first),
              ),

              // Custom / percentage inputs
              if (_splitType != SplitType.equal) ...[
                const SizedBox(height: 12),
                Text(
                  _splitType == SplitType.custom
                      ? 'Enter amount per member'
                      : 'Enter percentage per member',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ...widget.members.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextFormField(
                      controller: _customAmountCtrls[m.id],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: m.isSelf ? '${m.name} (You)' : m.name,
                        prefixText:
                            _splitType == SplitType.custom ? '₹ ' : null,
                        suffixText:
                            _splitType == SplitType.percentage ? '%' : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),

              // Note
              TextFormField(
                controller: _noteCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Expense'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _catLabel(String cat) {
    const labels = {
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
    return labels[cat] ?? cat;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _MemberAvatar extends StatelessWidget {
  final GroupMember member;
  const _MemberAvatar({required this.member});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor:
          member.isSelf ? AppColors.primaryContainer : AppColors.secondaryContainer,
      child: Text(
        member.initials,
        style: TextStyle(
          color: member.isSelf ? AppColors.primary : AppColors.secondary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

Widget _centeredHint(String text) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
