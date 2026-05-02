import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/folder.dart';
import '../data/folder_providers.dart';
import '../data/folder_repository.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/folders/add');
          ref.invalidate(foldersProvider);
          ref.invalidate(activeFoldersProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: foldersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (roots) {
          if (roots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No folders yet'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await context.push('/folders/add');
                      ref.invalidate(foldersProvider);
                    },
                    child: const Text('Add Folder'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(foldersProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...roots.map((folder) =>
                    _FolderTile(folder: folder, depth: 0, ref: ref)),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FolderTile extends StatefulWidget {
  final Folder folder;
  final int depth;
  final WidgetRef ref;

  const _FolderTile({
    required this.folder,
    required this.depth,
    required this.ref,
  });

  @override
  State<_FolderTile> createState() => _FolderTileState();
}

class _FolderTileState extends State<_FolderTile> {
  bool _expanded = true;

  Color get _color {
    try {
      return Color(
          int.parse(widget.folder.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;
    final hasChildren = folder.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: hasChildren ? () => setState(() => _expanded = !_expanded) : null,
          onLongPress: () => _showOptions(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.only(
              left: widget.depth * 20.0 + 8,
              right: 8,
              top: 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                Icon(_folderIcon(folder.icon), color: _color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    folder.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: widget.depth == 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'Add subfolder',
                  onPressed: widget.depth < 2
                      ? () async {
                          await context.push('/folders/add',
                              extra: folder.id);
                          widget.ref.invalidate(foldersProvider);
                        }
                      : null,
                ),
                if (hasChildren)
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                    color: Colors.grey,
                  ),
              ],
            ),
          ),
        ),
        if (hasChildren && _expanded)
          ...folder.children.map((child) =>
              _FolderTile(folder: child, depth: widget.depth + 1, ref: widget.ref)),
      ],
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () async {
                Navigator.pop(context);
                await context.push('/folders/add', extra: widget.folder);
                widget.ref.invalidate(foldersProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive'),
              onTap: () async {
                Navigator.pop(context);
                await FolderRepository().archiveFolder(widget.folder.id);
                widget.ref.invalidate(foldersProvider);
                widget.ref.invalidate(activeFoldersProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _folderIcon(String icon) {
    switch (icon) {
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
      default:
        return Icons.folder_outlined;
    }
  }
}
