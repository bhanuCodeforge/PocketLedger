import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/settings/data/user_profile_repository.dart';
import '../../../features/auth/data/security_repository.dart';
import '../../../features/wallets/data/wallet_providers.dart';
import '../../../core/providers/auth_state_provider.dart';
import '../../../generated/l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Onboarding state
  String _selectedCurrency = 'INR';
  String _selectedCurrencySymbol = '₹';
  final _walletNameController = TextEditingController(text: 'My Wallet');
  final _openingBalanceController = TextEditingController(text: '0');
  final _pinController = TextEditingController();
  final _pinConfirmController = TextEditingController();
  String _pinError = '';
  bool _pinObscure = true;
  bool _pinConfirmObscure = true;

  static const _currencies = [
    ('INR', '₹', 'Indian Rupee'),
    ('USD', '\$', 'US Dollar'),
    ('EUR', '€', 'Euro'),
    ('GBP', '£', 'British Pound'),
    ('JPY', '¥', 'Japanese Yen'),
    ('AED', 'د.إ', 'UAE Dirham'),
    ('SAR', 'ر.س', 'Saudi Riyal'),
    ('SGD', 'S\$', 'Singapore Dollar'),
    ('AUD', 'A\$', 'Australian Dollar'),
    ('CAD', 'C\$', 'Canadian Dollar'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _walletNameController.dispose();
    _openingBalanceController.dispose();
    _pinController.dispose();
    _pinConfirmController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    // Strip to digits only before comparing
    final pin1 = _pinController.text.replaceAll(RegExp(r'\D'), '');
    final pin2 = _pinConfirmController.text.replaceAll(RegExp(r'\D'), '');

    if (pin1.length != 6) {
      setState(() => _pinError = AppLocalizations.of(context).errorPinTooShort);
      return;
    }
    if (pin1 != pin2) {
      setState(() => _pinError = AppLocalizations.of(context).errorPinMismatch);
      return;
    }

    setState(() => _pinError = '');

    try {
      final profileRepo = ref.read(userProfileRepositoryProvider);
      final securityRepo = ref.read(securityRepositoryProvider);
      final db = await profileRepo.db;
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Create wallet first
      final walletId = now.toString();
      final walletName = _walletNameController.text.trim().isEmpty
          ? 'My Wallet'
          : _walletNameController.text.trim();
      await db.insert('wallets', {
        'id': walletId,
        'name': walletName,
        'type': 'cash',
        'opening_balance': double.tryParse(_openingBalanceController.text) ?? 0.0,
        'color': '#2563EB',
        'icon': 'account_balance_wallet',
        'is_archived': 0,
        'sort_order': 0,
        'created_at': now,
        'updated_at': now,
      });

      // 2. Save profile with wallet + onboarding complete
      await profileRepo.upsertProfile(UserProfile(
        currencyCode: _selectedCurrency,
        currencySymbol: _selectedCurrencySymbol,
        languageCode: 'en',
        themeMode: 'system',
        isOnboardingComplete: true,
        defaultWalletId: walletId,
        name: '',
      ));

      // 3. Set PIN
      await securityRepo.setPIN(pin1);

      // 4. Invalidate cached providers so fresh data loads on dashboard
      ref.invalidate(walletsProvider);

      // Authenticate and navigate
      ref.read(authStateProvider.notifier).authenticate();
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(5, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i <= _currentPage ? scheme.primary : scheme.outlineVariant,
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _CurrencyPage(
                    currencies: _currencies,
                    selected: _selectedCurrency,
                    onChanged: (code, symbol) {
                      setState(() {
                        _selectedCurrency = code;
                        _selectedCurrencySymbol = symbol;
                      });
                    },
                    onNext: _nextPage,
                    onBack: _prevPage,
                  ),
                  _WalletPage(
                    nameController: _walletNameController,
                    balanceController: _openingBalanceController,
                    currencySymbol: _selectedCurrencySymbol,
                    onNext: _nextPage,
                    onBack: _prevPage,
                  ),
                  _PinPage(
                    pinController: _pinController,
                    obscure: _pinObscure,
                    onToggleObscure: () => setState(() => _pinObscure = !_pinObscure),
                    onNext: _nextPage,
                    onBack: _prevPage,
                  ),
                  _PinConfirmPage(
                    pinConfirmController: _pinConfirmController,
                    obscure: _pinConfirmObscure,
                    onToggleObscure: () => setState(() => _pinConfirmObscure = !_pinConfirmObscure),
                    pinError: _pinError,
                    onComplete: _completeOnboarding,
                    onBack: _prevPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: Welcome ──────────────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 72,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            l10n.onboardingWelcomeTitle,
            style: AppTextStyles.headlineMedium.copyWith(color: scheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingWelcomeSubtitle,
            style: AppTextStyles.bodyLarge.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: Text(l10n.next),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Currency ─────────────────────────────────────────────────────────
class _CurrencyPage extends StatelessWidget {
  final List<(String, String, String)> currencies;
  final String selected;
  final void Function(String code, String symbol) onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _CurrencyPage({
    required this.currencies,
    required this.selected,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.onboardingCurrencyTitle,
                style: AppTextStyles.headlineSmall.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingCurrencySubtitle,
                style: AppTextStyles.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: currencies.length,
            itemBuilder: (context, i) {
              final (code, symbol, name) = currencies[i];
              final isSelected = code == selected;
              return ListTile(
                onTap: () => onChanged(code, symbol),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    symbol,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                title: Text(code, style: AppTextStyles.titleSmall),
                subtitle: Text(name, style: AppTextStyles.bodySmall),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                    : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              OutlinedButton(onPressed: onBack, child: Text(l10n.back)),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(onPressed: onNext, child: Text(l10n.next)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Page 3: Wallet ───────────────────────────────────────────────────────────
class _WalletPage extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController balanceController;
  final String currencySymbol;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _WalletPage({
    required this.nameController,
    required this.balanceController,
    required this.currencySymbol,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingWalletTitle,
            style: AppTextStyles.headlineSmall.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingWalletSubtitle,
            style: AppTextStyles.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: l10n.walletTitle,
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.walletOpeningBalance,
              prefixText: '$currencySymbol ',
            ),
          ),
          const Spacer(),
          Row(
            children: [
              OutlinedButton(onPressed: onBack, child: Text(l10n.back)),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(onPressed: onNext, child: Text(l10n.next)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page 4: PIN entry ────────────────────────────────────────────────────────
class _PinPage extends StatelessWidget {
  final TextEditingController pinController;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _PinPage({
    required this.pinController,
    required this.obscure,
    required this.onToggleObscure,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingPinTitle,
            style: AppTextStyles.headlineSmall.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingPinSubtitle,
            style: AppTextStyles.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: pinController,
            obscureText: obscure,
            maxLength: 6,
            keyboardType: TextInputType.number,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.onboardingPinTitle,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggleObscure,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              OutlinedButton(onPressed: onBack, child: Text(l10n.back)),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final digits = pinController.text.replaceAll(RegExp(r'\D'), '');
                    if (digits.length == 6) onNext();
                  },
                  child: Text(l10n.next),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page 5: PIN confirm ──────────────────────────────────────────────────────
class _PinConfirmPage extends StatelessWidget {
  final TextEditingController pinConfirmController;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String pinError;
  final Future<void> Function() onComplete;
  final VoidCallback onBack;

  const _PinConfirmPage({
    required this.pinConfirmController,
    required this.obscure,
    required this.onToggleObscure,
    required this.pinError,
    required this.onComplete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingPinConfirmTitle,
            style: AppTextStyles.headlineSmall.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingPinConfirmSubtitle,
            style: AppTextStyles.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: pinConfirmController,
            obscureText: obscure,
            maxLength: 6,
            keyboardType: TextInputType.number,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.onboardingPinConfirmTitle,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggleObscure,
              ),
              errorText: pinError.isEmpty ? null : pinError,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              OutlinedButton(onPressed: onBack, child: Text(l10n.back)),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onComplete,
                  child: Text(l10n.done),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
