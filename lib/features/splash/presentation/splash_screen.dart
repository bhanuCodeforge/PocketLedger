import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_init_provider.dart';
import '../../../core/providers/auth_state_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  void _navigate(BuildContext context, WidgetRef ref, AppInitState state) {
    if (!state.isOnboardingComplete) {
      context.go('/onboarding');
    } else if (state.hasPIN) {
      context.go('/lock');
    } else {
      ref.read(authStateProvider.notifier).authenticate();
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInit = ref.watch(appInitProvider);
    final scheme = Theme.of(context).colorScheme;

    ref.listen(appInitProvider, (_, next) {
      if (next.hasValue) {
        _navigate(context, ref, next.value!);
      }
    });

    // Handle the case where the provider already resolved before listener registered
    if (appInit.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _navigate(context, ref, appInit.value!);
        }
      });
    }

    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'PocketLedger',
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your personal finance manager',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 48),
            if (appInit.isLoading)
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Colors.white.withValues(alpha: 0.8),
                  strokeWidth: 2.5,
                ),
              ),
            if (appInit.hasError)
              Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to start. Please restart.',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
