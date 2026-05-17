import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../data/user_profile_repository.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _currencyCode = 'INR';
  String _currencySymbol = '₹';
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initFromProfile(UserProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = profile.name;
    _currencyCode = profile.currencyCode;
    _currencySymbol = profile.currencySymbol;
  }

  Future<void> _save(UserProfile current) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final updated = current.copyWith(
        name: _nameController.text.trim(),
        currencyCode: _currencyCode,
        currencySymbol: _currencySymbol,
      );
      await ref.read(userProfileProvider.notifier).updateProfile(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final scheme = Theme.of(context).colorScheme;

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.settingsProfile)),
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        if (profile != null) _initFromProfile(profile);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.settingsProfile),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: (_isSaving || profile == null)
                      ? null
                      : () => _save(profile),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Avatar display ────────────────────────────────────────
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: scheme.primaryContainer,
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _nameController,
                      builder: (_, value, __) => Text(
                        _initials(value.text),
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Name ──────────────────────────────────────────────────
                Text(
                  'Your Name',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Rahul',
                    prefixIcon: Icon(Icons.person_outline),
                    helperText: 'Shown as "Hi, [name]" on the dashboard',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (v.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // ── Currency ──────────────────────────────────────────────
                Text(
                  l10n.settingsCurrency,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your primary currency for the app',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ...AppConstants.currencies.map((currency) {
                  final isSelected = _currencyCode == currency['code'];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? BorderSide(color: scheme.primary, width: 2)
                          : BorderSide.none,
                    ),
                    child: RadioListTile<String>(
                      value: currency['code']!,
                      groupValue: _currencyCode,
                      title: Text(
                        currency['name']!,
                        style: AppTextStyles.titleSmall,
                      ),
                      subtitle: Text(
                        '${currency['code']} · ${currency['symbol']}',
                        style: AppTextStyles.bodySmall,
                      ),
                      secondary: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currency['symbol']!,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isSelected
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      activeColor: scheme.primary,
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _currencyCode = val;
                          _currencySymbol = currency['symbol']!;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return 'P';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
