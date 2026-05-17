import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../../expenses/data/expense.dart';
import '../../expenses/data/expense_providers.dart';
import '../../income/data/income.dart';
import '../../income/data/income_providers.dart';

// ── Filter enum ───────────────────────────────────────────────────────────────

enum _Filter { all, expenses, income }

// ── Unified result type ───────────────────────────────────────────────────────

sealed class _SearchResult {
  String get id;
  int get dateMs;
  double get amount;
}

class _ExpenseResult extends _SearchResult {
  final Expense e;
  _ExpenseResult(this.e);
  @override
  String get id => e.id;
  @override
  int get dateMs => e.expenseDate;
  @override
  double get amount => e.amount;
}

class _IncomeResult extends _SearchResult {
  final Income i;
  _IncomeResult(this.i);
  @override
  String get id => i.id;
  @override
  int get dateMs => i.incomeDate;
  @override
  double get amount => i.amount;
}

// ── SearchScreen ──────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  String _query = '';
  _Filter _filter = _Filter.all;
  bool _isLoading = false;
  List<_SearchResult> _results = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    // Auto-focus on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    _debounce?.cancel();
    if (text.trim().isEmpty) {
      setState(() {
        _query = '';
        _results = [];
        _isLoading = false;
        _error = null;
      });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(text.trim());
    });
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _query = query;
      _isLoading = true;
      _error = null;
    });
    try {
      final expRepo = ref.read(expenseRepositoryProvider);
      final incRepo = ref.read(incomeRepositoryProvider);

      final futures = await Future.wait([
        if (_filter == _Filter.all || _filter == _Filter.expenses)
          expRepo.search(query)
        else
          Future.value(<Expense>[]),
        if (_filter == _Filter.all || _filter == _Filter.income)
          incRepo.search(query)
        else
          Future.value(<Income>[]),
      ]);

      final expenses = futures[0] as List<Expense>;
      final incomes = futures[1] as List<Income>;

      final combined = <_SearchResult>[
        ...expenses.map(_ExpenseResult.new),
        ...incomes.map(_IncomeResult.new),
      ]..sort((a, b) => b.dateMs.compareTo(a.dateMs));

      if (mounted) {
        setState(() {
          _results = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _setFilter(_Filter f) {
    setState(() => _filter = f);
    if (_query.isNotEmpty) {
      _runSearch(_query);
    }
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _query = '';
      _results = [];
      _isLoading = false;
      _error = null;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = ref.watch(currencyProvider);
    final symbol = currency['symbol'] ?? '₹';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _SearchBar(
            controller: _controller,
            focusNode: _focusNode,
            hint: l10n.searchHint,
            onClear: _clearSearch,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Filter chips ─────────────────────────────────────────────
          _FilterBar(
            selected: _filter,
            onSelected: _setFilter,
            scheme: scheme,
          ),
          const Divider(height: 1),

          // ── Results / States ─────────────────────────────────────────
          Expanded(
            child: _buildBody(l10n, symbol, scheme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, String symbol, ColorScheme scheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '${l10n.error}: $_error',
            style: TextStyle(color: AppColors.expense),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_query.isEmpty) {
      return _IdleState(l10n: l10n, scheme: scheme);
    }

    if (_results.isEmpty) {
      return _EmptyState(query: _query, l10n: l10n, scheme: scheme);
    }

    return _ResultsList(
      results: _results,
      symbol: symbol,
      scheme: scheme,
      onTap: (result) {
        if (result is _ExpenseResult) {
          context.push('/expenses/${result.e.id}');
        }
        // Income detail navigation can be added when route is registered
      },
    );
  }
}

// ── _SearchBar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search_rounded, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: AppTextStyles.bodyMedium,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox(width: 12);
              return IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── _FilterBar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _Filter selected;
  final void Function(_Filter) onSelected;
  final ColorScheme scheme;

  const _FilterBar({
    required this.selected,
    required this.onSelected,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = [
      (_Filter.all, l10n.all),
      (_Filter.expenses, l10n.expenseTitle),
      (_Filter.income, l10n.incomeTitle),
    ];

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: filters.map((entry) {
          final (filter, label) = entry;
          final isSelected = filter == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onSelected(filter),
              selectedColor: AppColors.primary,
              labelStyle: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : scheme.onSurfaceVariant,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : scheme.outlineVariant,
              ),
              showCheckmark: false,
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── _ResultsList ──────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final List<_SearchResult> results;
  final String symbol;
  final ColorScheme scheme;
  final void Function(_SearchResult) onTap;

  const _ResultsList({
    required this.results,
    required this.symbol,
    required this.scheme,
    required this.onTap,
  });

  String _dateLabel(int epochMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, indent: 72, color: scheme.outlineVariant),
      itemBuilder: (context, i) {
        final result = results[i];
        return _ResultTile(
          result: result,
          symbol: symbol,
          dateLabel: _dateLabel(result.dateMs),
          scheme: scheme,
          onTap: () => onTap(result),
        );
      },
    );
  }
}

// ── _ResultTile ───────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final _SearchResult result;
  final String symbol;
  final String dateLabel;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _ResultTile({
    required this.result,
    required this.symbol,
    required this.dateLabel,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color iconColor;
    final Color badgeColor;
    final Color badgeFg;
    final String badgeLabel;
    final String title;
    final String subtitle;
    final Color amountColor;
    final String amountPrefix;

    if (result is _ExpenseResult) {
      final e = (result as _ExpenseResult).e;
      icon = e.category.icon;
      iconColor = e.category.color;
      badgeColor = AppColors.expenseLight;
      badgeFg = AppColors.expense;
      badgeLabel = 'E';
      title = e.category.label;
      subtitle = [
        if (e.note.isNotEmpty) e.note,
        e.paymentMode.label,
      ].join(' · ');
      amountColor = AppColors.expense;
      amountPrefix = '-';
    } else {
      final i = (result as _IncomeResult).i;
      icon = i.source.icon;
      iconColor = AppColors.income;
      badgeColor = AppColors.incomeLight;
      badgeFg = AppColors.income;
      badgeLabel = 'I';
      title = i.source.label;
      subtitle =
          i.note.isNotEmpty ? i.note : i.source.label;
      amountColor = AppColors.income;
      amountPrefix = '+';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBadgeBg =
        isDark ? badgeFg.withAlpha(40) : badgeColor;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Icon + type badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: effectiveBadgeBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.surface,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Amount + date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${CurrencyFormatter.formatSimple(result.amount, symbol)}',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── _IdleState ────────────────────────────────────────────────────────────────

class _IdleState extends StatelessWidget {
  final AppLocalizations l10n;
  final ColorScheme scheme;

  const _IdleState({required this.l10n, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 72,
            color: scheme.outlineVariant,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.searchHint,
            style: AppTextStyles.bodyLarge.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _HintChip(label: l10n.searchByNote, icon: Icons.notes_rounded),
              _HintChip(
                  label: l10n.searchByCategory,
                  icon: Icons.category_outlined),
              _HintChip(
                  label: l10n.searchByAmount,
                  icon: Icons.attach_money_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HintChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _EmptyState ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  final AppLocalizations l10n;
  final ColorScheme scheme;

  const _EmptyState({
    required this.query,
    required this.l10n,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: scheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.searchNoResults,
              style: AppTextStyles.titleSmall.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$query"',
              style: AppTextStyles.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
