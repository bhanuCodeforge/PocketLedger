import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'expense.dart';
import 'expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (_) => ExpenseRepository(),
);

/// All expenses ordered by date descending.
final expensesProvider = FutureProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getAll();
});

/// Total amount spent today.
final todayExpenseTotalProvider = FutureProvider<double>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getTodayTotal();
});

/// Expenses for a given (year, month) pair.
final expensesByMonthProvider =
    FutureProvider.family<List<Expense>, ({int year, int month})>(
  (ref, params) {
    final repo = ref.watch(expenseRepositoryProvider);
    return repo.getByMonth(params.year, params.month);
  },
);

/// Category totals for a date range (fromMs → toMs).
final categoryTotalsProvider =
    FutureProvider.family<Map<String, double>, ({int fromMs, int toMs})>(
  (ref, params) {
    final repo = ref.watch(expenseRepositoryProvider);
    return repo.getCategoryTotals(params.fromMs, params.toMs);
  },
);
