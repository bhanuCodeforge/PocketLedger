import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_init_provider.dart';
import 'core/providers/auth_state_provider.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/providers/locale_provider.dart';
import 'generated/l10n/app_localizations.dart';

class PocketLedgerApp extends ConsumerStatefulWidget {
  const PocketLedgerApp({super.key});

  @override
  ConsumerState<PocketLedgerApp> createState() => _PocketLedgerAppState();
}

class _PocketLedgerAppState extends ConsumerState<PocketLedgerApp>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkAutoLock();
    }
  }

  void _checkAutoLock() {
    final bg = _backgroundedAt;
    if (bg == null) return;
    final elapsed = DateTime.now().difference(bg);
    // Default lock after 5 minutes; could read from profile
    const lockAfter = Duration(minutes: 5);
    if (elapsed >= lockAfter) {
      ref.read(authStateProvider.notifier).lock();
    }
    _backgroundedAt = null;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    // Apply persisted theme + locale once app init is done
    ref.listen(appInitProvider, (_, next) {
      if (next.hasValue) {
        final state = next.value!;
        ref.read(themeProvider.notifier).setFromString(state.themeMode);
        ref.read(localeProvider.notifier).setFromString(state.languageCode);
      }
    });

    return MaterialApp.router(
      title: 'PocketLedger',
      debugShowCheckedModeBanner: false,

      // ── Theme ────────────────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // ── Localization ─────────────────────────────────────────────────────
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supported) {
        if (locale != null) return locale;
        if (deviceLocale != null) {
          for (final sup in supportedLocales) {
            if (sup.languageCode == deviceLocale.languageCode) {
              return sup;
            }
          }
        }
        return const Locale('en');
      },

      // ── Router ───────────────────────────────────────────────────────────
      routerConfig: router,
    );
  }
}
