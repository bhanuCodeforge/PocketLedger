import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../data/wallet.dart';
import '../data/wallet_providers.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final walletsAsync = ref.watch(allWalletsProvider);
    final currency = ref.watch(currencyProvider);
    final symbol = currency['symbol'] ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.walletTitle),
        centerTitle: false,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'wallets_fab',
        onPressed: () async {
          await context.push('/wallets/add');
          ref.invalidate(allWalletsProvider);
          ref.invalidate(walletsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.expense),
              const SizedBox(height: 12),
              Text('Error: $e',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (wallets) {
          final active = wallets.where((w) => w.isActive).toList();
          final archived = wallets.where((w) => !w.isActive).toList();

          if (wallets.isEmpty) {
            return _EmptyState(
              onAdd: () async {
                await context.push('/wallets/add');
                ref.invalidate(allWalletsProvider);
                ref.invalidate(walletsProvider);
              },
              l10n: l10n,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allWalletsProvider);
              ref.invalidate(walletsProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _TotalBalanceCard(
                    wallets: active,
                    symbol: symbol,
                    ref: ref,
                  ),
                ),
                if (active.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _WalletCard(
                          wallet: active[index],
                          symbol: symbol,
                          activeCount: active.length,
                          ref: ref,
                          l10n: l10n,
                        ),
                        childCount: active.length,
                      ),
                    ),
                  ),
                if (archived.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.archive_outlined,
                              size: 16,
                              color: AppColors.darkOnSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'Archived',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.darkOnSurfaceVariant,
                                  letterSpacing: 0.8,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _WalletCard(
                          wallet: archived[index],
                          symbol: symbol,
                          activeCount: active.length,
                          ref: ref,
                          l10n: l10n,
                          isArchived: true,
                        ),
                        childCount: archived.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(
                  child: SizedBox(height: 96),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Total Balance Summary Card ───────────────────────────────────────────────

class _TotalBalanceCard extends ConsumerWidget {
  final List<Wallet> wallets;
  final String symbol;
  final WidgetRef ref;

  const _TotalBalanceCard({
    required this.wallets,
    required this.symbol,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch balance for each active wallet
    final balanceAsyncList = wallets
        .map((w) => ref.watch(walletBalanceProvider(w.id)))
        .toList();

    final allLoaded =
        balanceAsyncList.every((a) => a is AsyncData<double>);
    double total = 0;
    if (allLoaded) {
      for (final a in balanceAsyncList) {
        total += (a as AsyncData<double>).value;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.primaryContainer;
    final textColor = isDark
        ? AppColors.darkOnSurface
        : AppColors.onPrimaryContainer;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Total Balance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor.withAlpha(200),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${wallets.length} wallet${wallets.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          allLoaded
              ? Text(
                  CurrencyFormatter.formatSimple(total, symbol),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: total < 0 ? AppColors.expense : textColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                )
              : const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
        ],
      ),
    );
  }
}

// ─── Wallet Card ─────────────────────────────────────────────────────────────

class _WalletCard extends ConsumerWidget {
  final Wallet wallet;
  final String symbol;
  final int activeCount;
  final WidgetRef ref;
  final AppLocalizations l10n;
  final bool isArchived;

  const _WalletCard({
    required this.wallet,
    required this.symbol,
    required this.activeCount,
    required this.ref,
    required this.l10n,
    this.isArchived = false,
  });

  Color _accentColor() {
    if (wallet.color != null && wallet.color!.isNotEmpty) {
      try {
        return Color(int.parse(wallet.color!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    // Fallback by type
    switch (wallet.type) {
      case WalletType.cash:
        return AppColors.income;
      case WalletType.bank:
        return AppColors.primary;
      case WalletType.upi:
        return AppColors.secondary;
      case WalletType.creditCard:
        return AppColors.expense;
      case WalletType.business:
        return AppColors.warning;
      case WalletType.other:
        return AppColors.catOther;
    }
  }

  Future<void> _handleArchive(BuildContext context) async {
    if (!context.mounted) return;
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.walletArchive),
        content: Text(l10n.walletArchiveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning),
            child: Text(l10n.walletArchive),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    if (activeCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.walletMinOneActive),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final repo = ref.read(walletRepositoryProvider);
    await repo.archiveWallet(wallet.id);
    ref.invalidate(allWalletsProvider);
    ref.invalidate(walletsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${wallet.name} archived'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await repo.unarchiveWallet(wallet.id);
              ref.invalidate(allWalletsProvider);
              ref.invalidate(walletsProvider);
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleUnarchive(BuildContext context) async {
    final repo = ref.read(walletRepositoryProvider);
    await repo.unarchiveWallet(wallet.id);
    ref.invalidate(allWalletsProvider);
    ref.invalidate(walletsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${wallet.name} restored')),
      );
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(wallet.name,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const Divider(height: 1),
            if (!isArchived) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.edit),
                onTap: () async {
                  Navigator.pop(context);
                  await context.push('/wallets/add', extra: wallet);
                  ref.invalidate(allWalletsProvider);
                  ref.invalidate(walletsProvider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined,
                    color: AppColors.warning),
                title: Text(l10n.walletArchive,
                    style:
                        const TextStyle(color: AppColors.warning)),
                onTap: () {
                  Navigator.pop(context);
                  _handleArchive(context);
                },
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.unarchive_outlined,
                    color: AppColors.income),
                title: const Text('Restore',
                    style: TextStyle(color: AppColors.income)),
                onTap: () {
                  Navigator.pop(context);
                  _handleUnarchive(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider(wallet.id));
    final accent = _accentColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 1,
        shadowColor: accent.withAlpha(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isArchived
              ? null
              : () async {
                  await context.push('/wallets/add', extra: wallet);
                  ref.invalidate(allWalletsProvider);
                  ref.invalidate(walletsProvider);
                },
          onLongPress: () => _showOptions(context),
          child: Row(
            children: [
              // Left accent border
              Container(
                width: 5,
                height: 72,
                decoration: BoxDecoration(
                  color: isArchived ? Colors.grey : accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Wallet type icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isArchived ? Colors.grey : accent).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  wallet.type.icon,
                  color: isArchived ? Colors.grey : accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Name and type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isArchived ? Colors.grey : null,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isArchived ? Colors.grey : accent)
                            .withAlpha(18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        wallet.type.label,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: isArchived
                                  ? Colors.grey
                                  : accent,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              // Balance
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: balanceAsync.when(
                  loading: () => const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Text('—'),
                  data: (balance) => Text(
                    CurrencyFormatter.formatSimple(balance, symbol),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                          color: isArchived
                              ? Colors.grey
                              : (balance < 0
                                  ? AppColors.expense
                                  : AppColors.income),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  final AppLocalizations l10n;

  const _EmptyState({required this.onAdd, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.walletTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noData,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.walletAdd),
            ),
          ],
        ),
      ),
    );
  }
}
