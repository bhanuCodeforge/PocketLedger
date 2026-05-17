import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'group.dart';
import 'group_repository.dart';

final groupRepositoryProvider = Provider<GroupRepository>(
  (_) => GroupRepository(),
);

final groupsProvider = FutureProvider<List<SplitGroup>>((ref) {
  return ref.watch(groupRepositoryProvider).getGroups();
});

final groupMembersProvider =
    FutureProvider.family<List<GroupMember>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getMembers(groupId);
});

final groupTransactionsProvider =
    FutureProvider.family<List<GroupTransaction>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getTransactions(groupId);
});

final groupByIdProvider =
    FutureProvider.family<SplitGroup?, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getGroupById(groupId);
});

final groupBalanceProvider =
    FutureProvider.family<Map<String, double>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getGroupBalance(groupId);
});

final groupTotalProvider =
    FutureProvider.family<double, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getGroupTotal(groupId);
});
