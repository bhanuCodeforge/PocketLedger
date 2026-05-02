# Architecture: Navigation Map (GoRouter)

Full route tree, guards, transitions, and deep-link paths.

---

## Route Tree

```
/                           → SplashScreen (redirect logic)
/onboarding                 → OnboardingFlow
  /onboarding/welcome
  /onboarding/currency
  /onboarding/wallet
  /onboarding/pin
/lock                       → PINLockScreen
/dashboard                  → DashboardScreen [guarded]

/expenses                   → ExpenseListScreen [guarded]
/expenses/add               → AddExpenseScreen
/expenses/:id               → ExpenseDetailScreen
/expenses/:id/edit          → EditExpenseScreen

/income                     → IncomeListScreen [guarded]
/income/add                 → AddIncomeScreen
/income/:id                 → IncomeDetailScreen
/income/:id/edit            → EditIncomeScreen

/wallets                    → WalletListScreen [guarded]
/wallets/add                → AddWalletScreen
/wallets/:id                → WalletDetailScreen (transactions for wallet)
/wallets/:id/edit           → EditWalletScreen
/wallets/transfer           → WalletTransferScreen

/folders                    → FolderListScreen [guarded]
/folders/add                → AddFolderScreen
/folders/:id/edit           → EditFolderScreen

/loans                      → LoanListScreen [guarded]
/loans/add                  → AddLoanScreen
/loans/:id                  → LoanDetailScreen
/loans/:id/edit             → EditLoanScreen
/loans/:id/payments/add     → AddLoanPaymentScreen

/contacts                   → ContactListScreen [guarded]
/contacts/add               → AddContactScreen
/contacts/:id               → ContactDetailScreen
/contacts/:id/edit          → EditContactScreen

/groups                     → GroupListScreen [guarded]
/groups/add                 → AddGroupScreen
/groups/:id                 → GroupDetailScreen
/groups/:id/edit            → EditGroupScreen
/groups/:id/expenses/add    → AddGroupExpenseScreen

/budgets                    → BudgetListScreen [guarded]
/budgets/add                → AddBudgetScreen
/budgets/:id/edit           → EditBudgetScreen

/reports                    → ReportsScreen [guarded]
/reports/category           → CategoryBreakdownScreen
/reports/cashflow           → CashFlowScreen
/reports/loans              → LoanProfitScreen

/search                     → SearchScreen [guarded]

/settings                   → SettingsScreen [guarded]
/settings/profile           → EditProfileScreen
/settings/security          → SecuritySettingsScreen
/settings/security/pin      → ChangePINScreen
/settings/security/phrase   → ViewRecoveryPhraseScreen
/settings/backup            → BackupSettingsScreen
/settings/backup/restore    → RestoreScreen
/settings/notifications     → NotificationSettingsScreen
/settings/export            → ExportScreen

/insights                   → AIInsightsScreen [guarded]
/ocr                        → OCRScanScreen [guarded]
/sms-import                 → SMSImportScreen [guarded]
```

---

## GoRouter Configuration

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final appInit = ref.watch(appInitProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      // Still loading
      if (appInit.isLoading) return null;

      // Init error — show error screen
      if (appInit.hasError) return '/error';

      final result = appInit.value!;
      final loc = state.matchedLocation;

      // First time user
      if (result.isFirstTime && !loc.startsWith('/onboarding')) {
        return '/onboarding/welcome';
      }

      // Has PIN, not authenticated, not on lock/onboarding
      if (!result.isFirstTime && !isAuthenticated &&
          !loc.startsWith('/lock') && !loc.startsWith('/onboarding')) {
        return '/lock';
      }

      // Authenticated user hitting lock → dashboard
      if (isAuthenticated && loc == '/lock') return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/dashboard'),
      GoRoute(path: '/lock',        builder: (_, __) => const PINLockScreen()),
      _onboardingShell,
      _dashboardShell,
      ..._expenseRoutes,
      ..._incomeRoutes,
      ..._walletRoutes,
      ..._folderRoutes,
      ..._loanRoutes,
      ..._contactRoutes,
      ..._groupRoutes,
      ..._budgetRoutes,
      _reportsRoute,
      GoRoute(path: '/search',   builder: (_, __) => const SearchScreen()),
      _settingsShell,
      GoRoute(path: '/insights', builder: (_, __) => const AIInsightsScreen()),
      GoRoute(path: '/ocr',      builder: (_, __) => const OCRScanScreen()),
      GoRoute(path: '/sms-import', builder: (_, __) => const SMSImportScreen()),
    ],
  );
});
```

---

## Bottom Navigation Shell

The main app shell wraps all guarded routes in a `StatefulShellRoute` with bottom navigation:

```
Bottom Nav Tabs:
  0 → /dashboard     (Home icon)
  1 → /expenses      (Wallet icon)
  2 → /reports       (Bar chart icon)
  3 → /search        (Search icon)
  4 → /settings      (Settings icon)
```

Tab state is preserved across switches (each branch has its own Navigator stack).

---

## Page Transitions

| Route type | Transition |
|-----------|------------|
| Tab switch | Fade (instant, 150 ms) |
| Push (list → detail) | Slide from right (300 ms) |
| Modal sheets (Add/Edit) | Slide from bottom |
| Onboarding steps | Slide from right with fade |
| Lock screen | Fade |
| Full-screen image viewer | Fade + scale |

---

## Deep Links (Android intent / iOS universal link)

| Intent | Route |
|--------|-------|
| `pocketledger://add-expense` | `/expenses/add` |
| `pocketledger://add-income` | `/income/add` |
| `pocketledger://dashboard` | `/dashboard` |

Configure in `AndroidManifest.xml` and `Info.plist` with scheme `pocketledger`.

---

## Error Screen

```
/error  → ErrorScreen with retry button
         (shown on DB open failure or appInitProvider error)
```

---

## Navigation Utilities

```dart
// Extension for clean navigation from non-widget code
extension RouterExtension on WidgetRef {
  GoRouter get router => read(routerProvider);
}

// Usage in notifiers:
ref.router.push('/expenses/add');
ref.router.pop();
ref.router.go('/dashboard');
```
