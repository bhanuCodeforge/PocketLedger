import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_init_provider.dart';
import '../providers/auth_state_provider.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/pin_lock_screen.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/expenses/presentation/add_expense_screen.dart';
import '../../features/expenses/presentation/expense_detail_screen.dart';
import '../../features/income/presentation/income_screen.dart';
import '../../features/income/presentation/add_income_screen.dart';
import '../../features/wallets/presentation/wallets_screen.dart';
import '../../features/wallets/presentation/add_wallet_screen.dart';
import '../../features/loans/presentation/loans_screen.dart';
import '../../features/loans/presentation/add_loan_screen.dart';
import '../../features/loans/presentation/loan_detail_screen.dart';
import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/budgets/presentation/add_budget_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/theme_settings_screen.dart';
import '../../features/settings/presentation/language_settings_screen.dart';
import '../../features/settings/presentation/security_settings_screen.dart';
import '../../features/settings/presentation/backup_settings_screen.dart';
import '../../features/contacts/presentation/contacts_screen.dart';
import '../../features/contacts/presentation/add_contact_screen.dart';
import '../../features/contacts/data/contact.dart';
import '../../features/groups/presentation/groups_screen.dart';
import '../../features/groups/presentation/add_group_screen.dart';
import '../../features/groups/presentation/group_detail_screen.dart';
import '../../features/groups/data/group.dart';
import '../../features/budgets/data/budget.dart';
import '../../features/ocr/presentation/ocr_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/folders/presentation/folders_screen.dart';
import '../../features/folders/presentation/add_folder_screen.dart';
import '../../features/wallets/data/wallet.dart';
import '../../features/settings/presentation/profile_settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final appInit = ref.watch(appInitProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final location = state.uri.path;

      if (location == '/splash') return null;

      if (appInit.isLoading) return '/splash';
      if (appInit.hasError) return '/splash';

      final initState = appInit.value!;

      if (!initState.isOnboardingComplete) {
        if (location.startsWith('/onboarding')) return null;
        return '/onboarding';
      }

      if (initState.hasPIN && !authState) {
        if (location == '/lock') return null;
        return '/lock';
      }

      if (location == '/lock' && authState) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // ── Auth / init routes ───────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/lock',
        builder: (_, __) => const PinLockScreen(),
      ),

      // ── Shell (bottom navigation) ────────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (_, __) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/income',
            builder: (_, __) => const IncomeScreen(),
          ),
          GoRoute(
            path: '/wallets',
            builder: (_, __) => const WalletsScreen(),
          ),
          GoRoute(
            path: '/folders',
            builder: (_, __) => const FoldersScreen(),
          ),
          GoRoute(
            path: '/loans',
            builder: (_, __) => const LoansScreen(),
          ),
          GoRoute(
            path: '/budgets',
            builder: (_, __) => const BudgetsScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, __) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: '/contacts',
            builder: (_, __) => const ContactsScreen(),
          ),
          GoRoute(
            path: '/groups',
            builder: (_, __) => const GroupsScreen(),
          ),
          GoRoute(
            path: '/insights',
            builder: (_, __) => const InsightsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),

      // ── Full-screen routes (no shell / bottom nav) ───────────────────────
      // Expenses
      GoRoute(
        path: '/expenses/add',
        builder: (_, __) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: '/expenses/:id/edit',
        builder: (_, state) => AddExpenseScreen(
          editId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/expenses/:id',
        builder: (_, state) => ExpenseDetailScreen(
          id: state.pathParameters['id']!,
        ),
      ),

      // Income
      GoRoute(
        path: '/income/add',
        builder: (_, __) => const AddIncomeScreen(),
      ),
      GoRoute(
        path: '/income/:id/edit',
        builder: (_, state) => AddIncomeScreen(
          editId: state.pathParameters['id'],
        ),
      ),

      // Wallets
      GoRoute(
        path: '/wallets/add',
        builder: (_, state) => AddWalletScreen(
          wallet: state.extra as Wallet?,
        ),
      ),

      // Folders
      GoRoute(
        path: '/folders/add',
        builder: (_, state) => AddFolderScreen(
          extra: state.extra,
        ),
      ),

      // Loans
      GoRoute(
        path: '/loans/add',
        builder: (_, __) => const AddLoanScreen(),
      ),
      GoRoute(
        path: '/loans/:id',
        builder: (_, state) => LoanDetailScreen(
          id: state.pathParameters['id']!,
        ),
      ),

      // Budgets
      GoRoute(
        path: '/budgets/add',
        builder: (_, state) => AddBudgetScreen(
          editBudget: state.extra as Budget?,
        ),
      ),

      // Contacts
      GoRoute(
        path: '/contacts/add',
        builder: (_, state) => AddContactScreen(
          editContact: state.extra as Contact?,
        ),
      ),

      // Groups
      GoRoute(
        path: '/groups/add',
        builder: (_, state) => AddGroupScreen(
          editGroup: state.extra as SplitGroup?,
        ),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (_, state) => GroupDetailScreen(
          groupId: state.pathParameters['id']!,
        ),
      ),

      // OCR
      GoRoute(
        path: '/ocr',
        builder: (_, __) => const OcrScreen(),
      ),

      // Settings sub-screens
      GoRoute(
        path: '/settings/theme',
        builder: (_, __) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/language',
        builder: (_, __) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/security',
        builder: (_, __) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/backup',
        builder: (_, __) => const BackupSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/profile',
        builder: (_, __) => const ProfileSettingsScreen(),
      ),
    ],
  );
});
