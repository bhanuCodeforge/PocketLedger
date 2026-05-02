import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../auth/data/security_repository.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSecurity)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined),
            title: Text(l10n.settingsChangePIN),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: navigate to change PIN screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint_outlined),
            title: Text(l10n.settingsBiometrics),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(l10n.settingsAutoLock),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
