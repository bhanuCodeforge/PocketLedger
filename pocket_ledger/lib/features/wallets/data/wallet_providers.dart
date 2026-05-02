import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wallet.dart';
import 'wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (_) => WalletRepository(),
);

final walletsProvider = FutureProvider<List<Wallet>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getActiveWallets();
});

final allWalletsProvider = FutureProvider<List<Wallet>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getAllWallets();
});

final walletBalanceProvider =
    FutureProvider.family<double, String>((ref, walletId) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getWalletBalance(walletId);
});
