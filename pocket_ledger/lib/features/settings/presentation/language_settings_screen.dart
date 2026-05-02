import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/locale_provider.dart';
import '../data/user_profile_repository.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  static const _languages = [
    (Locale('en'), 'English', 'English'),
    (Locale('hi'), 'हिंदी', 'Hindi'),
    (Locale('ar'), 'العربية', 'Arabic'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider) ?? const Locale('en');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsLanguage)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _languages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final (locale, nativeName, englishName) = _languages[i];
          final isSelected = currentLocale.languageCode == locale.languageCode;
          return Card(
            child: RadioListTile<Locale>(
              value: locale,
              groupValue: currentLocale,
              onChanged: (v) async {
                if (v == null) return;
                ref.read(localeProvider.notifier).setLocale(v);
                final repo = ref.read(userProfileRepositoryProvider);
                await repo.updateLanguage(v.languageCode);
              },
              title: Text(nativeName, style: AppTextStyles.titleSmall),
              subtitle: Text(englishName, style: AppTextStyles.bodySmall),
              activeColor: scheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }
}
