import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../auth/data/security_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _securitySettingsProvider =
    FutureProvider<_SecurityState>((ref) async {
  final repo = ref.read(securityRepositoryProvider);
  final biometricEnabled = await repo.isBiometricEnabled();
  final autoLockMinutes = await repo.getAutoLockMinutes();
  final hasPIN = await repo.hasPIN();
  return _SecurityState(
    biometricEnabled: biometricEnabled,
    autoLockMinutes: autoLockMinutes,
    hasPIN: hasPIN,
  );
});

class _SecurityState {
  final bool biometricEnabled;
  final int autoLockMinutes;
  final bool hasPIN;

  const _SecurityState({
    required this.biometricEnabled,
    required this.autoLockMinutes,
    required this.hasPIN,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(_securitySettingsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSecurity)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) => ListView(
          children: [
            // ── PIN section ────────────────────────────────────────────────
            _SectionHeader(title: 'PIN Protection'),
            ListTile(
              leading: Icon(Icons.lock_reset_outlined, color: scheme.primary),
              title: Text(
                settings.hasPIN
                    ? l10n.settingsChangePIN
                    : 'Set PIN',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                settings.hasPIN
                    ? 'Change your ${AppConstants.pinLength}-digit PIN'
                    : 'Protect the app with a ${AppConstants.pinLength}-digit PIN',
                style: AppTextStyles.bodySmall
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
              trailing: Icon(Icons.chevron_right,
                  color: scheme.onSurfaceVariant),
              onTap: () => _showChangePinDialog(context, ref, settings.hasPIN),
            ),

            // ── Biometrics section ─────────────────────────────────────────
            const Divider(height: 24, indent: 16, endIndent: 16),
            _SectionHeader(title: 'Biometrics'),
            _BiometricTile(
              enabled: settings.biometricEnabled,
              hasPIN: settings.hasPIN,
              onChanged: (value) async {
                await _toggleBiometric(context, ref, value, settings.hasPIN);
              },
            ),

            // ── Auto-lock section ──────────────────────────────────────────
            const Divider(height: 24, indent: 16, endIndent: 16),
            _SectionHeader(title: 'Auto-Lock'),
            _AutoLockTile(
              currentMinutes: settings.autoLockMinutes,
              hasPIN: settings.hasPIN,
              onChanged: (minutes) async {
                final repo = ref.read(securityRepositoryProvider);
                await repo.setAutoLockMinutes(minutes);
                ref.invalidate(_securitySettingsProvider);
              },
            ),

            // ── Info box ────────────────────────────────────────────────────
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: scheme.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your PIN is hashed and never stored in plain text. '
                        'Biometrics are handled by your device\'s secure enclave.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Change PIN dialog ──────────────────────────────────────────────────────

  void _showChangePinDialog(
    BuildContext context,
    WidgetRef ref,
    bool hasPIN,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChangePinDialog(hasPIN: hasPIN, ref: ref),
    );
  }

  // ── Biometric toggle ───────────────────────────────────────────────────────

  Future<void> _toggleBiometric(
    BuildContext context,
    WidgetRef ref,
    bool enable,
    bool hasPIN,
  ) async {
    if (!hasPIN) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a PIN first before enabling biometrics.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics;
    final isAvailable = await auth.isDeviceSupported();

    if (!canCheck || !isAvailable) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication is not available on this device.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (enable) {
      try {
        final authenticated = await auth.authenticate(
          localizedReason:
              'Authenticate to enable biometric login for PocketLedger',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        if (!authenticated) return;
      } on PlatformException {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication failed.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    final repo = ref.read(securityRepositoryProvider);
    await repo.setBiometricEnabled(enable);
    ref.invalidate(_securitySettingsProvider);
  }
}

// ── Biometric tile ────────────────────────────────────────────────────────────

class _BiometricTile extends StatelessWidget {
  final bool enabled;
  final bool hasPIN;
  final ValueChanged<bool> onChanged;

  const _BiometricTile({
    required this.enabled,
    required this.hasPIN,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        Icons.fingerprint_outlined,
        color: hasPIN ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(l10n.settingsBiometrics, style: AppTextStyles.bodyLarge),
      subtitle: Text(
        hasPIN
            ? 'Use fingerprint or face to unlock'
            : 'Set a PIN first to enable biometrics',
        style: AppTextStyles.bodySmall
            .copyWith(color: scheme.onSurfaceVariant),
      ),
      trailing: Switch(
        value: enabled,
        onChanged: hasPIN ? onChanged : null,
      ),
    );
  }
}

// ── Auto-lock tile ────────────────────────────────────────────────────────────

class _AutoLockTile extends StatelessWidget {
  final int currentMinutes;
  final bool hasPIN;
  final ValueChanged<int> onChanged;

  const _AutoLockTile({
    required this.currentMinutes,
    required this.hasPIN,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        Icons.timer_outlined,
        color: hasPIN ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(l10n.settingsAutoLock, style: AppTextStyles.bodyLarge),
      subtitle: Text(
        hasPIN ? _label(currentMinutes) : 'Set a PIN first to configure auto-lock',
        style: AppTextStyles.bodySmall
            .copyWith(color: scheme.onSurfaceVariant),
      ),
      trailing: hasPIN
          ? Icon(Icons.chevron_right, color: scheme.onSurfaceVariant)
          : null,
      onTap: hasPIN
          ? () => _showAutoLockSheet(context)
          : null,
    );
  }

  void _showAutoLockSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AutoLockSheet(
        currentMinutes: currentMinutes,
        onChanged: onChanged,
      ),
    );
  }

  String _label(int minutes) {
    if (minutes == 0) return 'Never (app stays unlocked)';
    if (minutes == 1) return 'After 1 minute of inactivity';
    return 'After $minutes minutes of inactivity';
  }
}

// ── Auto-lock bottom sheet ────────────────────────────────────────────────────

class _AutoLockSheet extends StatelessWidget {
  final int currentMinutes;
  final ValueChanged<int> onChanged;

  const _AutoLockSheet({
    required this.currentMinutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: scheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Auto-Lock After',
            style: AppTextStyles.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        ...AppConstants.autoLockOptions.map((minutes) {
          final isSelected = minutes == currentMinutes;
          return ListTile(
            title: Text(
              _label(minutes),
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected ? scheme.primary : scheme.onSurface,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check, color: scheme.primary)
                : null,
            onTap: () {
              onChanged(minutes);
              Navigator.of(context).pop();
            },
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  String _label(int minutes) {
    if (minutes == 0) return 'Never';
    if (minutes == 1) return '1 minute';
    return '$minutes minutes';
  }
}

// ── Change PIN dialog ─────────────────────────────────────────────────────────

class _ChangePinDialog extends StatefulWidget {
  final bool hasPIN;
  final WidgetRef ref;

  const _ChangePinDialog({required this.hasPIN, required this.ref});

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final repo = widget.ref.read(securityRepositoryProvider);

    try {
      // Verify current PIN if one is set
      if (widget.hasPIN) {
        final isValid = await repo.verifyPIN(_oldPinController.text);
        if (!isValid) {
          setState(() {
            _saving = false;
            _errorMessage = 'Current PIN is incorrect.';
          });
          return;
        }
      }

      await repo.setPIN(_newPinController.text);
      widget.ref.invalidate(_securitySettingsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.hasPIN ? 'PIN changed successfully.' : 'PIN set successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.hasPIN ? 'Change PIN' : 'Set PIN'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: scheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Current PIN (only when changing)
            if (widget.hasPIN) ...[
              TextFormField(
                controller: _oldPinController,
                decoration: const InputDecoration(
                  labelText: 'Current PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: AppConstants.pinLength,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter current PIN';
                  if (v.length != AppConstants.pinLength) {
                    return 'PIN must be ${AppConstants.pinLength} digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],

            // New PIN
            TextFormField(
              controller: _newPinController,
              decoration: InputDecoration(
                labelText: widget.hasPIN ? 'New PIN' : 'Enter PIN',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_open_outlined),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: AppConstants.pinLength,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter new PIN';
                if (v.length != AppConstants.pinLength) {
                  return 'PIN must be ${AppConstants.pinLength} digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Confirm PIN
            TextFormField(
              controller: _confirmPinController,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: AppConstants.pinLength,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your new PIN';
                if (v != _newPinController.text) return 'PINs do not match';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.hasPIN ? 'Change' : 'Set PIN'),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
