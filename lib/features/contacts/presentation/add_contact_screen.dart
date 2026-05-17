import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../data/contact.dart';
import '../data/contact_repository.dart';

class AddContactScreen extends StatefulWidget {
  final Contact? editContact;

  const AddContactScreen({super.key, this.editContact});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.editContact != null;

  @override
  void initState() {
    super.initState();
    final c = widget.editContact;
    if (c != null) {
      _nameController.text = c.name;
      _phoneController.text = c.phone ?? '';
      _emailController.text = c.email ?? '';
      _noteController.text = c.note;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ContactRepository();
      final now = DateTime.now().millisecondsSinceEpoch;
      final contact = Contact(
        id: widget.editContact?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        note: _noteController.text.trim(),
        avatarPath: widget.editContact?.avatarPath,
        createdAt: widget.editContact?.createdAt ?? now,
        updatedAt: now,
      );
      if (_isEditing) {
        await repo.update(contact);
      } else {
        await repo.create(contact);
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.edit : l10n.contactAdd),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
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
          padding: const EdgeInsets.all(16),
          children: [
            // ── Avatar placeholder ──────────────────────────────────────────
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Name ───────────────────────────────────────────────────────
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.required : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // ── Phone ──────────────────────────────────────────────────────
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // ── Email ──────────────────────────────────────────────────────
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final emailRx = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                if (!emailRx.hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Note ───────────────────────────────────────────────────────
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: '${l10n.note} (optional)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 40),

            // ── Save button ─────────────────────────────────────────────────
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
