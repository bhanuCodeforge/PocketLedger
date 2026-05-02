import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/theme_provider.dart';
import '../data/user_profile_repository.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentTheme = ref.watch(themeProvider);
    final scheme = Theme.of(context).colorScheme;

    final options = [
      (ThemeMode.light, l10n.settingsThemeLight, Icons.light_mode_outlined),
      (ThemeMode.dark, l10n.settingsThemeDark, Icons.dark_mode_outlined),
      (ThemeMode.system, l10n.settingsThemeSystem, Icons.brightness_auto_outlined),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTheme)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final (mode, label, icon) = options[i];
          final isSelected = currentTheme == mode;
          return Card(
            child: RadioListTile<ThemeMode>(
              value: mode,
              groupValue: currentTheme,
              onChanged: (v) async {
                if (v == null) return;
                ref.read(themeProvider.notifier).setTheme(v);
                // Persist to DB
                final repo = ref.read(userProfileRepositoryProvider);
                await repo.updateThemeMode(
                  ref.read(themeProvider.notifier).currentString,
                );
              },
              title: Text(label, style: AppTextStyles.titleSmall),
              secondary: Icon(icon,
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant),
              activeColor: scheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }
}
