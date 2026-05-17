import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../auth/data/security_repository.dart';
import '../../backup/services/backup_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _lastBackupDateProvider = FutureProvider<String?>((ref) async {
  return BackupService.instance.getLastBackupDate();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class BackupSettingsScreen extends ConsumerWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lastBackupAsync = ref.watch(_lastBackupDateProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsBackup)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Last backup status ──────────────────────────────────────────
          _LastBackupBanner(lastBackupAsync: lastBackupAsync),
          const SizedBox(height: 16),

          // ── Backup now ──────────────────────────────────────────────────
          _ActionCard(
            icon: Icons.backup_outlined,
            iconColor: scheme.primary,
            title: l10n.settingsBackupNow,
            subtitle: 'Creates an encrypted backup of all your data.',
            buttonLabel: 'Backup Now',
            buttonIcon: Icons.cloud_upload_outlined,
            onTap: () => _doBackup(context, ref, l10n),
          ),
          const SizedBox(height: 12),

          // ── Restore ─────────────────────────────────────────────────────
          _ActionCard(
            icon: Icons.restore_outlined,
            iconColor: scheme.secondary,
            title: l10n.settingsRestore,
            subtitle:
                'Restore all data from a .plb backup file. This will overwrite current data.',
            buttonLabel: 'Restore from File',
            buttonIcon: Icons.file_open_outlined,
            destructive: true,
            onTap: () => _doRestore(context, ref, l10n),
          ),
          const SizedBox(height: 20),

          // ── Encryption note ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    color: scheme.onSecondaryContainer, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.backupEncrypted,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Google Drive (informational) ────────────────────────────────
          _SectionHeader(title: 'Google Drive'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.drive_file_move_outlined,
                            color: scheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cloud Backup',
                                style: AppTextStyles.titleSmall),
                            Text(
                              'Google Drive sync — coming soon',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Automatic cloud backups to Google Drive will be available '
                    'in a future update. Your local backups are already '
                    'encrypted and safe.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: null, // disabled — coming soon
                    icon: const Icon(Icons.login_outlined),
                    label: const Text('Sign in with Google'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Backup flow ────────────────────────────────────────────────────────────

  Future<void> _doBackup(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    // Require PIN for encryption
    final pin = await _askForPin(context, 'Enter your PIN to encrypt backup');
    if (pin == null || !context.mounted) return;

    // Verify PIN
    final secRepo = ref.read(securityRepositoryProvider);
    final isValid = await secRepo.verifyPIN(pin);
    if (!isValid) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Incorrect PIN.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // Derive key material from pin hash
    final pinHash = await _getPinHash(pin);

    if (!context.mounted) return;

    // Show progress
    _showProgressDialog(context, 'Creating backup...');

    try {
      final path = await BackupService.instance.createLocalBackup(pinHash);
      if (context.mounted) {
        Navigator.of(context).pop(); // close progress
        ref.invalidate(_lastBackupDateProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.backupSuccess}\n${_shortPath(path)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // close progress
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.backupFailed}: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // ── Restore flow ───────────────────────────────────────────────────────────

  Future<void> _doRestore(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    // Confirm before restore
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore from Backup?'),
        content: const Text(
          'This will replace ALL current data with the backup. '
          'This action cannot be undone.\n\n'
          'Make sure you have the correct backup file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Pick a file (show input dialog for file path since file_picker not in pubspec)
    final filePath = await _askForFilePath(context);
    if (filePath == null || !context.mounted) return;

    if (!File(filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File not found at the given path.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Ask for PIN
    final pin = await _askForPin(context, 'Enter your PIN to decrypt backup');
    if (pin == null || !context.mounted) return;

    final pinHash = await _getPinHash(pin);

    _showProgressDialog(context, 'Restoring backup...');

    try {
      await BackupService.instance.restoreFromFile(filePath, pinHash);
      if (context.mounted) {
        Navigator.of(context).pop(); // close progress
        ref.invalidate(_lastBackupDateProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.restoreSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // close progress
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.restoreFailed}: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showProgressDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Future<String?> _askForPin(BuildContext context, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter PIN'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<String?> _askForFilePath(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Backup File Path'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '/storage/.../pocket_ledger_backup_xxx.plb',
            border: OutlineInputBorder(),
            helperText: 'Full path to the .plb backup file',
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  /// Lightweight hash for use as AES key material without depending on
  /// SecurityRepository's internal salt (which is device-specific).
  Future<String> _getPinHash(String pin) async {
    // Simple deterministic hash: we use the PIN directly as key material here.
    // BackupService._deriveKey takes any non-empty string.
    return pin.padRight(64, '0');
  }

  String _shortPath(String path) {
    final parts = path.replaceAll('\\', '/').split('/');
    if (parts.length <= 2) return path;
    return '.../${parts.last}';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _LastBackupBanner extends StatelessWidget {
  final AsyncValue<String?> lastBackupAsync;
  const _LastBackupBanner({required this.lastBackupAsync});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.history_outlined, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: lastBackupAsync.when(
              loading: () => const Text('Checking backup history...'),
              error: (_, __) => const Text('Could not load backup history'),
              data: (date) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Last Backup', style: AppTextStyles.labelLarge),
                  Text(
                    date ?? 'No backup yet',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: AppTextStyles.titleSmall),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: destructive
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        side: BorderSide(color: scheme.error.withOpacity(0.5)),
                      ),
                      onPressed: onTap,
                      icon: Icon(buttonIcon),
                      label: Text(buttonLabel),
                    )
                  : FilledButton.icon(
                      onPressed: onTap,
                      icon: Icon(buttonIcon),
                      label: Text(buttonLabel),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}
