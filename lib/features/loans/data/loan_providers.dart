import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'loan.dart';
import 'loan_payment.dart';
import 'loan_repository.dart';

final loanRepositoryProvider = Provider<LoanRepository>(
  (_) => LoanRepository(),
);

final activeLoansProvider = FutureProvider<List<Loan>>((ref) {
  final repo = ref.watch(loanRepositoryProvider);
  return repo.getAll(settled: false);
});

final settledLoansProvider = FutureProvider<List<Loan>>((ref) {
  final repo = ref.watch(loanRepositoryProvider);
  return repo.getAll(settled: true);
});

final loanPaymentsProvider =
    FutureProvider.family<List<LoanPayment>, String>((ref, loanId) {
  final repo = ref.watch(loanRepositoryProvider);
  return repo.getPayments(loanId);
});

final loanTotalPaidProvider =
    FutureProvider.family<double, String>((ref, loanId) {
  final repo = ref.watch(loanRepositoryProvider);
  return repo.getTotalPaid(loanId);
});
