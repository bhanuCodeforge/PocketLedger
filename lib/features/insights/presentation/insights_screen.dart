import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../expenses/data/expense_providers.dart';
import '../../income/data/income_providers.dart';
import '../data/insight.dart';
import '../data/insight_providers.dart';
import '../services/insights_engine.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.insightsTitle),
        actions: [
          IconButton(
            tooltip: 'Regenerate insights',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _regenerate(context, ref),
          ),
        ],
      ),
      body: insightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorBody(message: err.toString()),
        data: (insights) => RefreshIndicator(
          onRefresh: () => _regenerate(context, ref),
          child: insights.isEmpty
              ? _EmptyState(l10n: l10n)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: insights.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _InsightCard(
                      insight: insights[index],
                      onDismiss: () async {
                        await ref
                            .read(insightRepositoryProvider)
                            .markRead(insights[index].id);
                        ref.invalidate(insightsProvider);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final expenses = await ref.read(expensesProvider.future);
    final incomes = await ref.read(incomeListProvider.future);
    final repo = ref.read(insightRepositoryProvider);
    final engine = InsightsEngine(repo);

    // budgets list is empty until the Budget data-layer is fully implemented.
    await engine.generateInsights(
      expenses: expenses,
      incomes: incomes,
      budgets: const [],
    );
    ref.invalidate(insightsProvider);
  }
}

// ── Insight card ──────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final AiInsight insight;
  final VoidCallback onDismiss;

  const _InsightCard({required this.insight, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final typeColor = _colorForType(insight.insightType);
    final typeIcon = _iconForType(insight.insightType);

    return Card(
      elevation: insight.isRead ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: insight.isRead
            ? BorderSide(
                color: isDark
                    ? AppColors.darkOutline
                    : AppColors.lightOutlineVariant,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon with coloured background
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: typeColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          insight.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: insight.isRead
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Unread blue dot
                      if (!insight.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: insight.isRead ? 0.5 : 0.8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Type label chip
                      _TypeChip(type: insight.insightType, color: typeColor),
                      // Dismiss button
                      if (!insight.isRead)
                        TextButton(
                          onPressed: onDismiss,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Dismiss'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForType(InsightType type) {
    switch (type) {
      case InsightType.spendingSpike:
        return AppColors.expense;
      case InsightType.budgetRisk:
        return AppColors.warning;
      case InsightType.savingOpportunity:
        return AppColors.income;
      case InsightType.anomaly:
        return AppColors.secondary;
    }
  }

  IconData _iconForType(InsightType type) {
    switch (type) {
      case InsightType.spendingSpike:
        return Icons.trending_up_rounded;
      case InsightType.budgetRisk:
        return Icons.warning_amber_rounded;
      case InsightType.savingOpportunity:
        return Icons.savings_rounded;
      case InsightType.anomaly:
        return Icons.notification_important_rounded;
    }
  }
}

// ── Type chip ─────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final InsightType type;
  final Color color;

  const _TypeChip({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label(type),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _label(InsightType type) {
    switch (type) {
      case InsightType.spendingSpike:
        return 'SPENDING';
      case InsightType.budgetRisk:
        return 'BUDGET';
      case InsightType.savingOpportunity:
        return 'SAVINGS';
      case InsightType.anomaly:
        return 'ANOMALY';
    }
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 72,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No insights yet.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep tracking your expenses and we\'ll surface\npersonalised tips here.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Error body ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;

  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48,
                color: AppColors.expense.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(
              'Could not load insights.',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
