import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'income.dart';
import 'income_repository.dart';

final incomeRepositoryProvider = Provider<IncomeRepository>(
  (_) => IncomeRepository(),
);

/// All income records, ordered by income_date DESC.
final incomeListProvider = FutureProvider<List<Income>>((ref) {
  final repo = ref.watch(incomeRepositoryProvider);
  return repo.getAll();
});

/// Sum of income recorded today.
final todayIncomeTotalProvider = FutureProvider<double>((ref) {
  final repo = ref.watch(incomeRepositoryProvider);
  return repo.getTodayTotal();
});

/// Sum of income for the current calendar month.
final currentMonthIncomeTotalProvider = FutureProvider<double>((ref) {
  final repo = ref.watch(incomeRepositoryProvider);
  final now = DateTime.now();
  return repo.getMonthTotal(now.year, now.month);
});

/// Income records for a specific wallet.
final incomeByWalletProvider =
    FutureProvider.family<List<Income>, String>((ref, walletId) {
  final repo = ref.watch(incomeRepositoryProvider);
  return repo.getAll(walletId: walletId);
});

/// Income records for a specific year-month.
final incomeByMonthProvider =
    FutureProvider.family<List<Income>, ({int year, int month})>(
  (ref, args) {
    final repo = ref.watch(incomeRepositoryProvider);
    return repo.getByMonth(args.year, args.month);
  },
);
