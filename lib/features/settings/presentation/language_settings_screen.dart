import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/locale_provider.dart';
import '../data/user_profile_repository.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  static const _languages = [
    _Language(
      locale: Locale('en'),
      nativeName: 'English',
      englishName: 'English',
      flag: '🇬🇧',
      isRtl: false,
    ),
    _Language(
      locale: Locale('hi'),
      nativeName: 'हिंदी',
      englishName: 'Hindi',
      flag: '🇮🇳',
      isRtl: false,
    ),
    _Language(
      locale: Locale('ar'),
      nativeName: 'العربية',
      englishName: 'Arabic',
      flag: '🇦🇪',
      isRtl: true,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider) ?? const Locale('en');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsLanguage)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Select the language you want to use in PocketLedger. '
              'The change applies immediately.',
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _languages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final lang = _languages[i];
                final isSelected =
                    currentLocale.languageCode == lang.locale.languageCode;
                return _LanguageCard(
                  language: lang,
                  isSelected: isSelected,
                  onTap: () async {
                    ref.read(localeProvider.notifier).setLocale(lang.locale);
                    final repo = ref.read(userProfileRepositoryProvider);
                    await repo.updateLanguage(lang.locale.languageCode);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _Language {
  final Locale locale;
  final String nativeName;
  final String englishName;
  final String flag;
  final bool isRtl;

  const _Language({
    required this.locale,
    required this.nativeName,
    required this.englishName,
    required this.flag,
    required this.isRtl,
  });
}

// ── Language card widget ──────────────────────────────────────────────────────

class _LanguageCard extends StatelessWidget {
  final _Language language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? scheme.primaryContainer.withOpacity(0.25)
            : scheme.surface,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Flag emoji
              Text(
                language.flag,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.nativeName,
                      style: AppTextStyles.titleSmall.copyWith(
                        color:
                            isSelected ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                    if (language.nativeName != language.englishName) ...[
                      const SizedBox(height: 2),
                      Text(
                        language.englishName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (language.isRtl) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'RTL',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? scheme.primary
                        : scheme.onSurfaceVariant.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
