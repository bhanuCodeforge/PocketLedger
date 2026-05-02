import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../data/wallet.dart';
import '../data/wallet_providers.dart';
import '../data/wallet_repository.dart';
import '../../../core/theme/app_colors.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final walletsAsync = ref.watch(allWalletsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.walletTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/wallets/add');
          ref.invalidate(allWalletsProvider);
          ref.invalidate(walletsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (wallets) {
          final active = wallets.where((w) => w.isActive).toList();
          final archived = wallets.where((w) => !w.isActive).toList();

          if (wallets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.noData,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await context.push('/wallets/add');
                      ref.invalidate(allWalletsProvider);
                    },
                    child: const Text('Add Wallet'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allWalletsProvider);
              ref.invalidate(walletsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...active.map((w) => _WalletCard(
                      wallet: w,
                      onEdit: () async {
                        await context.push('/wallets/add', extra: w);
                        ref.invalidate(allWalletsProvider);
                        ref.invalidate(walletsProvider);
                      },
                      onArchive: () async {
                        final count =
                            await WalletRepository().getActiveWalletCount();
                        if (count <= 1) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('At least one wallet is required.'),
                              ),
                            );
                          }
                          return;
                        }
                        await WalletRepository().archiveWallet(w.id);
                        ref.invalidate(allWalletsProvider);
                        ref.invalidate(walletsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${w.name} archived'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  await WalletRepository()
                                      .unarchiveWallet(w.id);
                                  ref.invalidate(allWalletsProvider);
                                  ref.invalidate(walletsProvider);
                                },
                              ),
                            ),
                          );
                        }
                      },
                    )),
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Archived',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.grey,
                          )),
                  const SizedBox(height: 8),
                  ...archived.map((w) => _WalletCard(
                        wallet: w,
                        onEdit: null,
                        onArchive: null,
                        onUnarchive: () async {
                          await WalletRepository().unarchiveWallet(w.id);
                          ref.invalidate(allWalletsProvider);
                          ref.invalidate(walletsProvider);
                        },
                      )),
                ],
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WalletCard extends ConsumerWidget {
  final Wallet wallet;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;

  const _WalletCard({
    required this.wallet,
    this.onEdit,
    this.onArchive,
    this.onUnarchive,
  });

  Color _walletColor() {
    if (wallet.color != null && wallet.color!.isNotEmpty) {
      try {
        return Color(int.parse(wallet.color!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider(wallet.id));
    final color = _walletColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        onLongPress: () => _showOptions(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(wallet.type.icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wallet.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(wallet.type.label,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
              balanceAsync.when(
                loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const Text('—'),
                data: (balance) => Text(
                  '₹${balance.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: balance < 0
                            ? AppColors.expense
                            : AppColors.income,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
            if (onArchive != null)
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archive'),
                onTap: () {
                  Navigator.pop(context);
                  onArchive?.call();
                },
              ),
            if (onUnarchive != null)
              ListTile(
                leading: const Icon(Icons.unarchive_outlined),
                title: const Text('Unarchive'),
                onTap: () {
                  Navigator.pop(context);
                  onUnarchive?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}
