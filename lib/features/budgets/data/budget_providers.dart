import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'budget.dart';
import 'budget_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (_) => BudgetRepository(),
);

final budgetsProvider = FutureProvider<List<Budget>>((ref) {
  return ref.watch(budgetRepositoryProvider).getAll();
});

final budgetsWithSpentProvider = FutureProvider<List<BudgetWithSpent>>((ref) {
  return ref.watch(budgetRepositoryProvider).getAllWithSpent();
});
