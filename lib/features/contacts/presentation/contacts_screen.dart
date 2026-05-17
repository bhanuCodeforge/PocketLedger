import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../data/contact.dart';
import '../data/contact_providers.dart';
import '../data/contact_repository.dart';
import 'add_contact_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddContactScreen()),
    );
    ref.invalidate(contactsProvider);
  }

  Future<void> _openEdit(Contact contact) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddContactScreen(editContact: contact)),
    );
    ref.invalidate(contactsProvider);
  }

  Future<void> _delete(Contact contact) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text('Delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ContactRepository().delete(contact.id);
      ref.invalidate(contactsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contactTitle),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        tooltip: l10n.contactAdd,
        child: const Icon(Icons.person_add_alt_1_outlined),
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: contactsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (contacts) {
                final filtered = _query.isEmpty
                    ? contacts
                    : contacts
                        .where((c) =>
                            c.name
                                .toLowerCase()
                                .contains(_query.toLowerCase()) ||
                            (c.phone ?? '')
                                .toLowerCase()
                                .contains(_query.toLowerCase()) ||
                            (c.email ?? '')
                                .toLowerCase()
                                .contains(_query.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.contacts_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(l10n.noData,
                            style: Theme.of(context).textTheme.bodyLarge),
                        if (_query.isEmpty) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _openAdd,
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: Text(l10n.contactAdd),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(contactsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final c = filtered[index];
                      return _ContactTile(
                        contact: c,
                        onEdit: () => _openEdit(c),
                        onDelete: () => _delete(c),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contact tile with swipe-to-delete ────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactTile({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(contact.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // we handle deletion in the callback
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _AvatarCircle(contact: contact),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (contact.phone != null && contact.phone!.isNotEmpty)
                        Text(
                          contact.phone!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                          maxLines: 1,
                        )
                      else if (contact.email != null &&
                          contact.email!.isNotEmpty)
                        Text(
                          contact.email!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading:
                            Icon(Icons.delete_outline, color: AppColors.expense),
                        title: Text('Delete',
                            style: TextStyle(color: AppColors.expense)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final Contact contact;
  const _AvatarCircle({required this.contact});

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    if (contact.avatarPath != null && contact.avatarPath!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: AssetImage(contact.avatarPath!),
      );
    }

    // Generate a stable color from name hash.
    final colors = [
      AppColors.primary,
      AppColors.income,
      AppColors.warning,
      AppColors.secondary,
      AppColors.catRent,
      AppColors.catEntertainment,
      AppColors.catTravel,
    ];
    final color = colors[contact.name.codeUnits
            .fold(0, (a, b) => a + b) %
        colors.length];

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withAlpha(40),
      child: Text(
        contact.initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
