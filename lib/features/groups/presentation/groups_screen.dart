import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../data/group.dart';
import '../data/group_providers.dart';
import '../data/group_repository.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupTitle),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/groups/add');
          ref.invalidate(groupsProvider);
        },
        tooltip: l10n.groupAdd,
        child: const Icon(Icons.add),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.expense),
              const SizedBox(height: 12),
              Text('Error: $e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(groupsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return _EmptyState(
              onAdd: () async {
                await context.push('/groups/add');
                ref.invalidate(groupsProvider);
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(groupsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final group = groups[index];
                return _GroupCard(
                  group: group,
                  onTap: () async {
                    await context.push('/groups/${group.id}');
                    ref.invalidate(groupsProvider);
                  },
                  onDelete: () async {
                    final confirmed = await _confirmDelete(context, l10n);
                    if (!confirmed) return;
                    await GroupRepository().deleteGroup(group.id);
                    ref.invalidate(groupsProvider);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: const Text(
            'Delete this group? All transactions and splits will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ).then((v) => v ?? false);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.groupTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group to split expenses with friends or family.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.groupAdd),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Group card ────────────────────────────────────────────────────────────────

class _GroupCard extends ConsumerWidget {
  final SplitGroup group;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membersAsync = ref.watch(groupMembersProvider(group.id));
    final totalAsync = ref.watch(groupTotalProvider(group.id));
    final balanceAsync = ref.watch(groupBalanceProvider(group.id));

    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              _GroupAvatar(name: group.name),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (group.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          group.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Member count
                        membersAsync.when(
                          data: (members) => _Chip(
                            icon: Icons.group_outlined,
                            label:
                                '${members.length} ${l10n.groupMembers.toLowerCase()}',
                            color: AppColors.primary,
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 8),
                        // Total
                        totalAsync.when(
                          data: (total) => _Chip(
                            icon: Icons.receipt_outlined,
                            label: '₹${total.toStringAsFixed(0)}',
                            color: AppColors.income,
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    // Balance status
                    balanceAsync.when(
                      data: (balance) {
                        final selfEntries = balance.entries
                            .where((e) => e.value.abs() > 0.01)
                            .toList();
                        if (selfEntries.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final isSettled = balance.values
                            .every((v) => v.abs() < 0.01);
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _Chip(
                            icon: isSettled
                                ? Icons.check_circle_outline
                                : Icons.pending_outlined,
                            label: isSettled
                                ? 'All settled'
                                : 'Unsettled balances',
                            color: isSettled
                                ? AppColors.income
                                : AppColors.warning,
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            color: AppColors.expense, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.delete,
                            style: const TextStyle(color: AppColors.expense)),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'delete') onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _GroupAvatar extends StatelessWidget {
  final String name;
  const _GroupAvatar({required this.name});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
}

// ── Small chip ────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
