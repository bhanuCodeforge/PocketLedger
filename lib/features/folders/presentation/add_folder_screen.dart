import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../data/folder.dart';
import '../data/folder_providers.dart';
import '../data/folder_repository.dart';

class AddFolderScreen extends ConsumerStatefulWidget {
  /// Pass a [Folder] to edit, a [String] parentId to pre-select parent,
  /// or null to create a root folder.
  final dynamic extra;

  const AddFolderScreen({super.key, this.extra});

  @override
  ConsumerState<AddFolderScreen> createState() => _AddFolderScreenState();
}

class _AddFolderScreenState extends ConsumerState<AddFolderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedColor = '#607D8B';
  String _selectedIcon = 'folder';
  String? _parentId;
  Folder? _editingFolder;
  bool _isSaving = false;

  static const _colors = [
    '#607D8B', // Blue Grey
    '#2563EB', // Blue
    '#16A34A', // Green
    '#DC2626', // Red
    '#D97706', // Amber
    '#7C3AED', // Violet
    '#DB2777', // Pink
    '#0891B2', // Cyan
    '#65A30D', // Lime
    '#EA580C', // Orange
    '#4B5563', // Gray
    '#0D9488', // Teal
    '#9333EA', // Purple
    '#E11D48', // Rose
    '#1D4ED8', // Blue Dark
    '#15803D', // Green Dark
  ];

  static const _icons = <(String, IconData)>[
    ('folder', Icons.folder_outlined),
    ('home', Icons.home_outlined),
    ('person', Icons.person_outline),
    ('group', Icons.group_outlined),
    ('business', Icons.business_outlined),
    ('restaurant', Icons.restaurant),
    ('shopping_cart', Icons.shopping_cart_outlined),
    ('bolt', Icons.bolt),
    ('car', Icons.directions_car_outlined),
    ('flight', Icons.flight),
    ('medical', Icons.medical_services_outlined),
    ('school', Icons.school_outlined),
    ('fitness', Icons.fitness_center),
    ('pets', Icons.pets),
    ('sports', Icons.sports_soccer),
    ('music', Icons.music_note_outlined),
    ('movie', Icons.movie_outlined),
    ('book', Icons.book_outlined),
    ('phone', Icons.phone_outlined),
    ('laptop', Icons.laptop_outlined),
  ];

  bool get _isEditing => _editingFolder != null;

  @override
  void initState() {
    super.initState();
    if (widget.extra is Folder) {
      _editingFolder = widget.extra as Folder;
      _nameController.text = _editingFolder!.name;
      _selectedColor = _editingFolder!.color;
      _selectedIcon = _editingFolder!.icon;
      _parentId = _editingFolder!.parentId;
    } else if (widget.extra is String) {
      _parentId = widget.extra as String;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = FolderRepository();
      final now = DateTime.now().millisecondsSinceEpoch;

      final folder = Folder(
        id: _editingFolder?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        parentId: _parentId,
        color: _selectedColor,
        icon: _selectedIcon,
        status: 'active',
        sortOrder: _editingFolder?.sortOrder ?? 0,
        createdAt: _editingFolder?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        await repo.updateFolder(folder);
      } else {
        await repo.createFolder(folder);
      }

      ref.invalidate(foldersProvider);
      ref.invalidate(activeFoldersProvider);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving folder: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _parseColor(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Folder' : 'Add Folder'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(
                      'Save',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Preview ────────────────────────────────────────────────
            _FolderPreview(
              name: _nameController.text.isEmpty
                  ? 'Folder Name'
                  : _nameController.text,
              color: accentColor,
              iconKey: _selectedIcon,
            ),
            const SizedBox(height: 24),

            // ── Name ──────────────────────────────────────────────────
            _SectionLabel(label: 'Folder Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Groceries, Travel, Work',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                prefixIcon: const Icon(Icons.folder_outlined),
                filled: true,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Folder name is required';
                }
                if (v.trim().length > 40) {
                  return 'Name must be 40 characters or less';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Parent Folder ─────────────────────────────────────────
            _SectionLabel(label: 'Parent Folder (optional)'),
            const SizedBox(height: 8),
            _ParentFolderDropdown(
              selectedId: _parentId,
              excludeId: _editingFolder?.id,
              onChanged: (id) => setState(() => _parentId = id),
              ref: ref,
            ),

            const SizedBox(height: 24),

            // ── Color ─────────────────────────────────────────────────
            _SectionLabel(label: 'Color'),
            const SizedBox(height: 10),
            _ColorPicker(
              colors: _colors,
              selected: _selectedColor,
              onChanged: (c) => setState(() => _selectedColor = c),
            ),

            const SizedBox(height: 24),

            // ── Icon ──────────────────────────────────────────────────
            _SectionLabel(label: 'Icon'),
            const SizedBox(height: 10),
            _IconPicker(
              icons: _icons,
              selected: _selectedIcon,
              accentColor: accentColor,
              onChanged: (i) => setState(() => _selectedIcon = i),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ─── Folder Preview ───────────────────────────────────────────────────────────

class _FolderPreview extends StatelessWidget {
  final String name;
  final Color color;
  final String iconKey;

  const _FolderPreview({
    required this.name,
    required this.color,
    required this.iconKey,
  });

  IconData _iconData() {
    const map = <String, IconData>{
      'folder': Icons.folder_outlined,
      'home': Icons.home_outlined,
      'person': Icons.person_outline,
      'group': Icons.group_outlined,
      'business': Icons.business_outlined,
      'restaurant': Icons.restaurant,
      'shopping_cart': Icons.shopping_cart_outlined,
      'bolt': Icons.bolt,
      'car': Icons.directions_car_outlined,
      'flight': Icons.flight,
      'medical': Icons.medical_services_outlined,
      'school': Icons.school_outlined,
      'fitness': Icons.fitness_center,
      'pets': Icons.pets,
      'sports': Icons.sports_soccer,
      'music': Icons.music_note_outlined,
      'movie': Icons.movie_outlined,
      'book': Icons.book_outlined,
      'phone': Icons.phone_outlined,
      'laptop': Icons.laptop_outlined,
    };
    return map[iconKey] ?? Icons.folder_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconData(), color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Parent Folder Dropdown ───────────────────────────────────────────────────

class _ParentFolderDropdown extends StatelessWidget {
  final String? selectedId;
  final String? excludeId;
  final ValueChanged<String?> onChanged;
  final WidgetRef ref;

  const _ParentFolderDropdown({
    required this.selectedId,
    required this.excludeId,
    required this.onChanged,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(activeFoldersProvider);

    return foldersAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (folders) {
        // Only show root folders (parentId == null) and exclude self
        final roots = folders
            .where((f) =>
                f.parentId == null &&
                (excludeId == null || f.id != excludeId))
            .toList();

        return DropdownButtonFormField<String?>(
          value: selectedId,
          decoration: const InputDecoration(
            hintText: 'None (root level)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            prefixIcon: Icon(Icons.account_tree_outlined),
            filled: true,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('None (root level)'),
            ),
            ...roots.map((f) {
              Color fColor;
              try {
                fColor =
                    Color(int.parse(f.color.replaceFirst('#', '0xFF')));
              } catch (_) {
                fColor = AppColors.primary;
              }
              return DropdownMenuItem<String?>(
                value: f.id,
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        color: fColor, size: 18),
                    const SizedBox(width: 8),
                    Text(f.name),
                  ],
                ),
              );
            }),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

// ─── Color Picker ─────────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  final List<String> colors;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ColorPicker({
    required this.colors,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((hex) {
        Color color;
        try {
          color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
        } catch (_) {
          color = AppColors.primary;
        }
        final isSelected = selected == hex;
        return GestureDetector(
          onTap: () => onChanged(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withAlpha(120),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ─── Icon Picker ──────────────────────────────────────────────────────────────

class _IconPicker extends StatelessWidget {
  final List<(String, IconData)> icons;
  final String selected;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  const _IconPicker({
    required this.icons,
    required this.selected,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 60,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final (name, iconData) = icons[index];
        final isSelected = selected == name;
        return GestureDetector(
          onTap: () => onChanged(name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withAlpha(30)
                  : Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: accentColor, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: Icon(
              iconData,
              color: isSelected ? accentColor : Colors.grey,
              size: 26,
            ),
          ),
        );
      },
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
    );
  }
}
