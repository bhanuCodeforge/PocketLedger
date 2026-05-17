import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/folder.dart';
import '../data/folder_providers.dart';
import '../data/folder_repository.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
        centerTitle: false,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'folders_fab',
        onPressed: () async {
          await context.push('/folders/add');
          ref.invalidate(foldersProvider);
          ref.invalidate(activeFoldersProvider);
        },
        child: const Icon(Icons.create_new_folder_outlined),
      ),
      body: foldersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.expense),
              const SizedBox(height: 12),
              Text('Error: $e', textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (roots) {
          if (roots.isEmpty) {
            return _EmptyFoldersState(
              onAdd: () async {
                await context.push('/folders/add');
                ref.invalidate(foldersProvider);
                ref.invalidate(activeFoldersProvider);
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(foldersProvider);
              ref.invalidate(activeFoldersProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: roots.map((folder) {
                return _FolderSection(folder: folder, ref: ref);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

// ─── Folder Section (root + children) ────────────────────────────────────────

class _FolderSection extends StatefulWidget {
  final Folder folder;
  final WidgetRef ref;

  const _FolderSection({required this.folder, required this.ref});

  @override
  State<_FolderSection> createState() => _FolderSectionState();
}

class _FolderSectionState extends State<_FolderSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  Color get _color {
    try {
      return Color(
          int.parse(widget.folder.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  bool get _hasChildren => widget.folder.children.isNotEmpty;
  int get _childCount => widget.folder.children.length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final color = _color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Root folder row
          _FolderRow(
            folder: widget.folder,
            color: color,
            depth: 0,
            hasChildren: _hasChildren,
            isExpanded: _expanded,
            onToggle: _hasChildren ? _toggleExpand : null,
            ref: widget.ref,
            isLast: true,
            showDivider: _hasChildren && _expanded,
          ),
          // Children
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                ...widget.folder.children.asMap().entries.map((entry) {
                  final i = entry.key;
                  final child = entry.value;
                  return _FolderRow(
                    folder: child,
                    color: _childColor(child),
                    depth: 1,
                    hasChildren: child.children.isNotEmpty,
                    isExpanded: false,
                    onToggle: null,
                    ref: widget.ref,
                    isLast: i == _childCount - 1,
                    showDivider: false,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _childColor(Folder child) {
    try {
      return Color(int.parse(child.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

// ─── Folder Row ───────────────────────────────────────────────────────────────

class _FolderRow extends StatelessWidget {
  final Folder folder;
  final Color color;
  final int depth;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final WidgetRef ref;
  final bool isLast;
  final bool showDivider;

  const _FolderRow({
    required this.folder,
    required this.color,
    required this.depth,
    required this.hasChildren,
    required this.isExpanded,
    required this.onToggle,
    required this.ref,
    required this.isLast,
    required this.showDivider,
  });

  IconData _iconData() {
    switch (folder.icon) {
      case 'person':
        return Icons.person_outline;
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'bolt':
        return Icons.bolt;
      case 'group':
        return Icons.group_outlined;
      case 'business':
        return Icons.business_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'car':
        return Icons.directions_car_outlined;
      case 'flight':
        return Icons.flight;
      case 'medical':
        return Icons.medical_services_outlined;
      case 'fitness':
        return Icons.fitness_center;
      case 'school':
        return Icons.school_outlined;
      case 'pets':
        return Icons.pets;
      case 'sports':
        return Icons.sports_soccer;
      case 'music':
        return Icons.music_note_outlined;
      case 'movie':
        return Icons.movie_outlined;
      case 'book':
        return Icons.book_outlined;
      case 'phone':
        return Icons.phone_outlined;
      case 'laptop':
        return Icons.laptop_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  Icon(_iconData(), color: color, size: 20),
                  const SizedBox(width: 10),
                  Text(folder.name,
                      style:
                          Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () async {
                Navigator.pop(context);
                await context.push('/folders/add', extra: folder);
                ref.invalidate(foldersProvider);
                ref.invalidate(activeFoldersProvider);
              },
            ),
            if (depth == 0)
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined,
                    color: AppColors.primary),
                title: const Text('Add Subfolder',
                    style: TextStyle(color: AppColors.primary)),
                onTap: () async {
                  Navigator.pop(context);
                  await context.push('/folders/add',
                      extra: folder.id);
                  ref.invalidate(foldersProvider);
                  ref.invalidate(activeFoldersProvider);
                },
              ),
            ListTile(
              leading: const Icon(Icons.archive_outlined,
                  color: AppColors.warning),
              title: const Text('Archive',
                  style: TextStyle(color: AppColors.warning)),
              onTap: () async {
                Navigator.pop(context);
                await _confirmAndArchive(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndArchive(BuildContext context) async {
    final hasKids = folder.children.isNotEmpty;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Folder'),
        content: Text(
          hasKids
              ? 'Archiving "${folder.name}" will also archive all its subfolders. Continue?'
              : 'Archive "${folder.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = FolderRepository();
    await repo.archiveFolder(folder.id);
    ref.invalidate(foldersProvider);
    ref.invalidate(activeFoldersProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${folder.name}" archived')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indent = depth * 20.0;

    return Column(
      children: [
        if (depth > 0)
          Divider(
            height: 1,
            indent: 16 + indent,
            color: isDark
                ? AppColors.darkOutlineVariant
                : AppColors.lightOutlineVariant,
          ),
        InkWell(
          borderRadius: depth == 0 && !showDivider
              ? BorderRadius.circular(14)
              : BorderRadius.zero,
          onTap: onToggle ??
              () => _showOptions(context),
          onLongPress: () => _showOptions(context),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                16 + indent, 14, 12, 14),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withAlpha(depth == 0 ? 28 : 20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconData(),
                      color: color,
                      size: depth == 0 ? 20 : 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: depth == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasChildren)
                        Text(
                          '${folder.children.length} subfolder${folder.children.length == 1 ? '' : 's'}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                // Add subfolder button (only root, depth 0)
                if (depth == 0)
                  Tooltip(
                    message: 'Add subfolder',
                    child: IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      color: AppColors.primary,
                      onPressed: () async {
                        await context.push('/folders/add',
                            extra: folder.id);
                        ref.invalidate(foldersProvider);
                        ref.invalidate(activeFoldersProvider);
                      },
                    ),
                  ),
                // Expand/collapse indicator
                if (hasChildren && onToggle != null)
                  AnimatedRotation(
                    turns: isExpanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more,
                        size: 20, color: Colors.grey),
                  ),
                // Options for leaf/child rows
                if (depth > 0 || (depth == 0 && onToggle == null))
                  IconButton(
                    icon: const Icon(Icons.more_vert,
                        size: 20, color: Colors.grey),
                    onPressed: () => _showOptions(context),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyFoldersState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyFoldersState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Folders Yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Organize your transactions with folders',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Add Folder'),
            ),
          ],
        ),
      ),
    );
  }
}
