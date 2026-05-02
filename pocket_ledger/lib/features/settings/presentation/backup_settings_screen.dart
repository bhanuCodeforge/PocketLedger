import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../generated/l10n/app_localizations.dart';

class BackupSettingsScreen extends ConsumerWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsBackup)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.backup_outlined, color: scheme.primary),
              title: Text(l10n.settingsBackupNow),
              subtitle: const Text('Backup to Google Drive'),
              onTap: () {
                // TODO: implement backup
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.restore_outlined, color: scheme.primary),
              title: Text(l10n.settingsRestore),
              subtitle: const Text('Restore from Google Drive'),
              onTap: () {
                // TODO: implement restore
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.backupEncrypted,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
