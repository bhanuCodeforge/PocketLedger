import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/providers/auth_state_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/security_repository.dart';
import '../../../generated/l10n/app_localizations.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen>
    with SingleTickerProviderStateMixin {
  static const int _pinLength = 6;
  static const int _maxAttempts = 5;

  String _enteredPin = '';
  int _wrongAttempts = 0;
  bool _isLoading = false;
  bool _isLocked = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _loadState();
    _tryBiometrics();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final repo = ref.read(securityRepositoryProvider);
    final attempts = await repo.getWrongAttempts();
    if (mounted) {
      setState(() {
        _wrongAttempts = attempts;
        _isLocked = attempts >= _maxAttempts;
      });
    }
  }

  Future<void> _tryBiometrics() async {
    final repo = ref.read(securityRepositoryProvider);
    final biometricEnabled = await repo.isBiometricEnabled();
    if (!biometricEnabled) return;

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return;

      final l10n = AppLocalizations.of(context);
      final authenticated = await _localAuth.authenticate(
        localizedReason: l10n.lockBiometricsPrompt,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        await _onAuthenticated();
      }
    } catch (_) {
      // Biometric unavailable — fall back to PIN
    }
  }

  Future<void> _onAuthenticated() async {
    final repo = ref.read(securityRepositoryProvider);
    await repo.resetWrongAttempts();
    ref.read(authStateProvider.notifier).authenticate();
    if (mounted) context.go('/dashboard');
  }

  void _onDigitPressed(String digit) {
    if (_isLoading || _isLocked || _enteredPin.length >= _pinLength) return;
    setState(() => _enteredPin += digit);
    if (_enteredPin.length == _pinLength) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);
    final repo = ref.read(securityRepositoryProvider);
    final isCorrect = await repo.verifyPIN(_enteredPin);

    if (isCorrect) {
      await _onAuthenticated();
      return;
    }

    // Wrong PIN
    await repo.incrementWrongAttempts();
    _wrongAttempts++;

    HapticFeedback.mediumImpact();
    _shakeController.forward(from: 0);

    setState(() {
      _enteredPin = '';
      _isLoading = false;
      _isLocked = _wrongAttempts >= _maxAttempts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // App icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: scheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isLocked ? l10n.lockAccountLocked : l10n.lockEnterPin,
              style: AppTextStyles.titleLarge.copyWith(color: scheme.onSurface),
            ),
            if (_wrongAttempts > 0 && !_isLocked) ...[
              const SizedBox(height: 8),
              Text(
                l10n.lockWrongPin(_maxAttempts - _wrongAttempts),
                style: AppTextStyles.bodySmall.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: 40),

            // PIN dots with shake animation
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final offset = sin(_shakeAnimation.value * pi * 8) * 12;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? scheme.primary : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? scheme.primary
                            : scheme.outline,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(),

            // Numpad
            if (!_isLocked)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    for (final row in [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                    ]) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map((d) => _DigitButton(
                          digit: d,
                          onTap: () => _onDigitPressed(d),
                        )).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Biometric
                        _ActionButton(
                          icon: Icons.fingerprint,
                          onTap: _tryBiometrics,
                        ),
                        _DigitButton(digit: '0', onTap: () => _onDigitPressed('0')),
                        _ActionButton(
                          icon: Icons.backspace_outlined,
                          onTap: _onBackspace,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                // TODO: navigate to recovery phrase screen
              },
              child: Text(l10n.lockForgotPin),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DigitButton extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;

  const _DigitButton({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceContainerHighest,
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
            style: AppTextStyles.headlineSmall.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Icon(icon, color: scheme.onSurfaceVariant, size: 28),
        ),
      ),
    );
  }
}
