import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../data/folder.dart';
import '../data/folder_repository.dart';

class AddFolderScreen extends StatefulWidget {
  final dynamic extra; // String parentId or Folder to edit

  const AddFolderScreen({super.key, this.extra});

  @override
  State<AddFolderScreen> createState() => _AddFolderScreenState();
}

class _AddFolderScreenState extends State<AddFolderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedColor = '#607D8B';
  String _selectedIcon = 'folder';
  bool _isSaving = false;
  String? _parentId;
  Folder? _editingFolder;

  static const _colors = [
    '#607D8B', '#2563EB', '#16A34A', '#DC2626', '#D97706',
    '#7C3AED', '#DB2777', '#0891B2', '#65A30D', '#EA580C',
    '#4B5563', '#1E293B', '#9333EA', '#E11D48', '#0D9488',
    '#F59E0B',
  ];

  static const _icons = [
    ('folder', Icons.folder_outlined),
    ('person', Icons.person_outline),
    ('restaurant', Icons.restaurant),
    ('shopping_cart', Icons.shopping_cart_outlined),
    ('bolt', Icons.bolt),
    ('group', Icons.group_outlined),
    ('business', Icons.business_outlined),
    ('home', Icons.home_outlined),
    ('car', Icons.directions_car_outlined),
    ('flight', Icons.flight),
    ('medical', Icons.medical_services_outlined),
    ('fitness', Icons.fitness_center),
    ('school', Icons.school_outlined),
    ('pets', Icons.pets),
    ('sports', Icons.sports_soccer),
    ('music', Icons.music_note_outlined),
    ('movie', Icons.movie_outlined),
    ('book', Icons.book_outlined),
    ('phone', Icons.phone_outlined),
    ('laptop', Icons.laptop_outlined),
  ];

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
        sortOrder: _editingFolder?.sortOrder ?? 0,
        createdAt: _editingFolder?.createdAt ?? now,
        updatedAt: now,
      );
      if (_editingFolder == null) {
        await repo.createFolder(folder);
      } else {
        await repo.updateFolder(folder);
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingFolder != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Folder' : 'Add Folder'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Folder Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((hex) {
                final color =
                    Color(int.parse(hex.replaceFirst('#', '0xFF')));
                final selected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: selected
                          ? [BoxShadow(color: color.withAlpha(128), blurRadius: 6)]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Icon', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((entry) {
                final (name, iconData) = entry;
                final selected = _selectedIcon == name;
                final color = Color(
                    int.parse(_selectedColor.replaceFirst('#', '0xFF')));
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = name),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withAlpha(30)
                          : Colors.grey.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: selected
                          ? Border.all(color: color, width: 2)
                          : null,
                    ),
                    child: Icon(iconData,
                        color: selected ? color : Colors.grey, size: 24),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
