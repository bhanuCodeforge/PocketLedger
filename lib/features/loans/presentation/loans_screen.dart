import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../data/loan.dart';
import '../data/loan_providers.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addLoan() async {
    await context.push('/loans/add');
    ref.invalidate(activeLoansProvider);
    ref.invalidate(settledLoansProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loanTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Settled'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLoan,
        tooltip: l10n.loanAdd,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LoanList(settled: false),
          _LoanList(settled: true),
        ],
      ),
    );
  }
}

// ── Loan list tab ─────────────────────────────────────────────────────────────

class _LoanList extends ConsumerWidget {
  final bool settled;
  const _LoanList({required this.settled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final loansAsync =
        settled ? ref.watch(settledLoansProvider) : ref.watch(activeLoansProvider);
    final currency = ref.watch(currencyProvider);
    final symbol = currency['symbol'] ?? '₹';

    return loansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (loans) {
        if (loans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  settled
                      ? Icons.check_circle_outline
                      : Icons.handshake_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(l10n.noData,
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeLoansProvider);
            ref.invalidate(settledLoansProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: loans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) => _LoanCard(
              loan: loans[index],
              symbol: symbol,
              onTap: () async {
                await context.push('/loans/${loans[index].id}');
                ref.invalidate(activeLoansProvider);
                ref.invalidate(settledLoansProvider);
              },
            ),
          ),
        );
      },
    );
  }
}

// ── Loan card ─────────────────────────────────────────────────────────────────

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final String symbol;
  final VoidCallback onTap;

  const _LoanCard({
    required this.loan,
    required this.symbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final due = loan.totalDue(now);
    final isGiven = loan.type == LoanType.given;
    final typeColor = isGiven ? AppColors.income : AppColors.expense;
    final typeLabel = isGiven ? 'Given' : 'Taken';

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────
              Row(
                children: [
                  // Type badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: typeColor.withAlpha(80)),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loan.contactName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (loan.isSettled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.income.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Settled',
                        style: TextStyle(
                          color: AppColors.income,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (loan.isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Overdue',
                        style: TextStyle(
                          color: AppColors.expense,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Amounts row ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Principal',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey)),
                      Text(
                        '$symbol${loan.principalAmount.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total Due',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey)),
                      Text(
                        '$symbol${due.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: typeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Due date ─────────────────────────────────────────────────
              if (loan.dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: loan.isOverdue
                          ? AppColors.expense
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(
                          DateTime.fromMillisecondsSinceEpoch(loan.dueDate!)),
                      style: TextStyle(
                        fontSize: 12,
                        color: loan.isOverdue
                            ? AppColors.expense
                            : Colors.grey,
                        fontWeight: loan.isOverdue
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (loan.isOverdue) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '• Overdue',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // ── Progress bar (paid/total) ─────────────────────────────────
              if (!loan.isSettled) ...[
                const SizedBox(height: 10),
                _PaidProgressBar(loan: loan, symbol: symbol),
              ],
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

// ── Paid progress bar (loads payment total async) ─────────────────────────────

class _PaidProgressBar extends ConsumerWidget {
  final Loan loan;
  final String symbol;
  const _PaidProgressBar({required this.loan, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPaidAsync = ref.watch(loanTotalPaidProvider(loan.id));
    final due = loan.totalDue(DateTime.now());

    return totalPaidAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (paid) {
        final progress = due > 0 ? (paid / due).clamp(0.0, 1.0) : 0.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid: $symbol${paid.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  'Remaining: $symbol${(due - paid).clamp(0, double.infinity).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.withAlpha(40),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? AppColors.income : AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
