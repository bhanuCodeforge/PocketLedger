import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
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
      _ThemeOption(
        mode: ThemeMode.light,
        label: l10n.settingsThemeLight,
        icon: Icons.light_mode_outlined,
        description: 'Classic bright interface — great for daytime use.',
        previewBg: Colors.white,
        previewSurface: const Color(0xFFF1F5F9),
        previewText: const Color(0xFF0F172A),
        previewAccent: AppColors.primary,
      ),
      _ThemeOption(
        mode: ThemeMode.dark,
        label: l10n.settingsThemeDark,
        icon: Icons.dark_mode_outlined,
        description: 'Dark interface — easy on the eyes at night.',
        previewBg: AppColors.darkBackground,
        previewSurface: AppColors.darkSurface,
        previewText: AppColors.darkOnSurface,
        previewAccent: AppColors.primaryLight,
      ),
      _ThemeOption(
        mode: ThemeMode.system,
        label: l10n.settingsThemeSystem,
        icon: Icons.brightness_auto_outlined,
        description: 'Follows your device\'s system dark/light setting.',
        previewBg: const Color(0xFFF8FAFC),
        previewSurface: const Color(0xFFE2E8F0),
        previewText: const Color(0xFF0F172A),
        previewAccent: AppColors.primary,
        isDual: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTheme)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final option = options[i];
          final isSelected = currentTheme == option.mode;
          return _ThemeCard(
            option: option,
            isSelected: isSelected,
            onTap: () async {
              ref.read(themeProvider.notifier).setTheme(option.mode);
              // Persist to DB
              final repo = ref.read(userProfileRepositoryProvider);
              await repo.updateThemeMode(
                ref.read(themeProvider.notifier).currentString,
              );
            },
          );
        },
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _ThemeOption {
  final ThemeMode mode;
  final String label;
  final IconData icon;
  final String description;
  final Color previewBg;
  final Color previewSurface;
  final Color previewText;
  final Color previewAccent;
  final bool isDual;

  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.icon,
    required this.description,
    required this.previewBg,
    required this.previewSurface,
    required this.previewText,
    required this.previewAccent,
    this.isDual = false,
  });
}

// ── Card widget ───────────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  final _ThemeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? scheme.primaryContainer.withOpacity(0.3)
            : scheme.surface,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Preview thumbnail
              _ThemePreviewThumbnail(option: option),
              const SizedBox(width: 16),
              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          option.icon,
                          size: 18,
                          color: isSelected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          option.label,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isSelected
                                ? scheme.primary
                                : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Radio indicator
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? scheme.primary
                        : scheme.onSurfaceVariant.withOpacity(0.4),
                    width: isSelected ? 6 : 2,
                  ),
                  color: isSelected ? scheme.primary : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini preview thumbnail ────────────────────────────────────────────────────

class _ThemePreviewThumbnail extends StatelessWidget {
  final _ThemeOption option;
  const _ThemePreviewThumbnail({required this.option});

  @override
  Widget build(BuildContext context) {
    if (option.isDual) {
      // System: half light, half dark
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 64,
          height: 56,
          child: Row(
            children: [
              Expanded(child: _buildHalf(Colors.white, const Color(0xFF0F172A), AppColors.primary)),
              Expanded(child: _buildHalf(AppColors.darkSurface, AppColors.darkOnSurface, AppColors.primaryLight)),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 64,
        height: 56,
        color: option.previewBg,
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: option.previewAccent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 6,
              width: 36,
              decoration: BoxDecoration(
                color: option.previewText.withOpacity(0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: option.previewSurface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHalf(Color bg, Color text, Color accent) {
    return Container(
      color: bg,
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 4,
            width: 12,
            decoration: BoxDecoration(
              color: text.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: text.withOpacity(0.05),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
