import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'insight.dart';
import 'insight_repository.dart';

/// Singleton repository instance for AI insights.
final insightRepositoryProvider = Provider<InsightRepository>(
  (_) => InsightRepository(),
);

/// All non-expired insights: unread first, then read, newest first within each
/// group.  Consumers should call [ref.refresh] after regenerating insights.
final insightsProvider = FutureProvider<List<AiInsight>>((ref) async {
  final repo = ref.watch(insightRepositoryProvider);
  // Clean up stale rows first so the list is always fresh.
  await repo.deleteExpired();
  return repo.getAll();
});

/// Only unread insights (badge counts, notification dots, etc.).
final unreadInsightsProvider = FutureProvider<List<AiInsight>>((ref) async {
  final repo = ref.watch(insightRepositoryProvider);
  return repo.getAll(unreadOnly: true);
});

/// Unread insight count – handy for a badge on the nav-bar icon.
final unreadInsightCountProvider = FutureProvider<int>((ref) async {
  final list = await ref.watch(unreadInsightsProvider.future);
  return list.length;
});
