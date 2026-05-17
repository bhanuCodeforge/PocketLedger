import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../data/user_profile_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(userProfileProvider);
    final currentTheme = ref.watch(themeProvider);

    final profile = profileAsync.maybeWhen(
      data: (p) => p,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // ── Profile card ─────────────────────────────────────────────────
          _ProfileCard(profile: profile),
          const SizedBox(height: 8),

          // ── Preferences ──────────────────────────────────────────────────
          _SectionHeader(title: 'Preferences'),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: l10n.settingsTheme,
            subtitle: _themeLabel(currentTheme, l10n),
            onTap: () => context.push('/settings/theme'),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: l10n.settingsLanguage,
            subtitle: _languageLabel(profile?.languageCode),
            onTap: () => context.push('/settings/language'),
          ),
          _SettingsTile(
            icon: Icons.attach_money_outlined,
            title: l10n.settingsCurrency,
            subtitle: profile != null
                ? '${profile.currencyCode} (${profile.currencySymbol})'
                : null,
            onTap: () => context.push('/settings/profile'),
          ),
          _SettingsTile(
            icon: Icons.folder_outlined,
            title: 'Folders',
            onTap: () => context.push('/folders'),
          ),

          // ── Security ─────────────────────────────────────────────────────
          const Divider(height: 24, indent: 16, endIndent: 16),
          _SectionHeader(title: l10n.settingsSecurity),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: l10n.settingsSecurity,
            subtitle: 'PIN, biometrics & auto-lock',
            onTap: () => context.push('/settings/security'),
          ),

          // ── Backup ───────────────────────────────────────────────────────
          const Divider(height: 24, indent: 16, endIndent: 16),
          _SectionHeader(title: l10n.settingsBackup),
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: l10n.settingsBackup,
            subtitle: 'Local encrypted backups',
            onTap: () => context.push('/settings/backup'),
          ),

          // ── About ────────────────────────────────────────────────────────
          const Divider(height: 24, indent: 16, endIndent: 16),
          _SectionHeader(title: l10n.settingsAbout),
          _SettingsTile(
            icon: Icons.info_outline,
            title: '${l10n.settingsAbout} ${l10n.settingsVersion}',
            subtitle: AppConstants.appVersion,
            showChevron: false,
            onTap: () => _showAboutDialog(context),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Open Source Licenses',
            showChevron: true,
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppConstants.appName,
              applicationVersion: AppConstants.appVersion,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode, AppLocalizations l10n) {
    return switch (mode) {
      ThemeMode.light => l10n.settingsThemeLight,
      ThemeMode.dark => l10n.settingsThemeDark,
      ThemeMode.system => l10n.settingsThemeSystem,
    };
  }

  String _languageLabel(String? code) {
    return switch (code) {
      'hi' => 'हिंदी',
      'ar' => 'العربية',
      _ => 'English',
    };
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationLegalese: '© 2026 PocketLedger. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'PocketLedger is a personal finance manager that helps you track '
          'expenses, income, loans, and budgets — all stored locally on your '
          'device.',
        ),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends ConsumerWidget {
  final UserProfile? profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: InkWell(
        onTap: () => context.push('/settings/profile'),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.primary,
                child: Text(
                  _initials(profile?.name),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: scheme.onPrimary,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name.isNotEmpty == true
                          ? profile!.name
                          : 'Your Profile',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile != null
                          ? '${profile!.currencyCode} · ${_languageLabel(profile!.languageCode)}'
                          : 'Tap to set up your profile',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: scheme.onPrimaryContainer.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'P';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _languageLabel(String code) {
    return switch (code) {
      'hi' => 'Hindi',
      'ar' => 'Arabic',
      _ => 'English',
    };
  }
}

// ── Generic settings tile ─────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: showChevron
          ? Icon(Icons.chevron_right, color: scheme.onSurfaceVariant)
          : null,
      onTap: onTap,
    );
  }
}
