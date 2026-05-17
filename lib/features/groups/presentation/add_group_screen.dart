import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../data/group.dart';
import '../data/group_providers.dart';
import '../data/group_repository.dart';

class AddGroupScreen extends ConsumerStatefulWidget {
  /// When non-null, the screen edits an existing group.
  final SplitGroup? editGroup;

  const AddGroupScreen({super.key, this.editGroup});

  @override
  ConsumerState<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends ConsumerState<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _saving = false;

  bool get _isEditing => widget.editGroup != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameCtrl.text = widget.editGroup!.name;
      _descCtrl.text = widget.editGroup!.description;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(groupRepositoryProvider);
      final now = DateTime.now().millisecondsSinceEpoch;

      if (_isEditing) {
        final updated = widget.editGroup!.copyWith(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          updatedAt: now,
        );
        await repo.updateGroup(updated);
        if (mounted) {
          ref.invalidate(groupsProvider);
          context.pop();
        }
      } else {
        final draft = SplitGroup(
          id: '',
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        final newId = await repo.createGroup(draft);
        if (mounted) {
          ref.invalidate(groupsProvider);
          // Navigate to the detail screen so the user can add members immediately.
          context.pushReplacement('/groups/$newId');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.edit : l10n.groupAdd),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Icon / avatar placeholder
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_outlined,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Group name
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g. Weekend Trip, Flatmates…',
                prefixIcon: const Icon(Icons.group_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.required;
                if (v.trim().length < 2) return 'Name must be at least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this group for?',
                prefixIcon: const Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 32),

            if (!_isEditing) ...[
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Create & Add Members'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'After creating the group you can add members and record expenses.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.55),
                    ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.save),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
