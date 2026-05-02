import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/providers/locale_provider.dart';
import '../data/user_profile_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(title: l10n.settingsProfile),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.settingsProfile),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/profile'),
          ),
          const Divider(),
          _SectionHeader(title: 'Preferences'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.settingsTheme),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/theme'),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(l10n.settingsLanguage),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/language'),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money_outlined),
            title: Text(l10n.settingsCurrency),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Folders'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/folders'),
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsSecurity),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.settingsSecurity),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/security'),
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsBackup),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(l10n.settingsBackup),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/backup'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAbout),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: scheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
