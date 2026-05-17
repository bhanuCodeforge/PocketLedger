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

      // Always allow splash
      if (location == '/splash') return null;

      // Wait for init
      if (appInit.isLoading) return '/splash';
      if (appInit.hasError) return '/splash';

      final initState = appInit.value!;

      // First launch → onboarding
      if (!initState.isOnboardingComplete) {
        if (location.startsWith('/onboarding')) return null;
        return '/onboarding';
      }

      // Has PIN and not authenticated → lock screen
      if (initState.hasPIN && !authState) {
        if (location == '/lock') return null;
        return '/lock';
      }

      // Authenticated user trying to go to lock → dashboard
      if (location == '/lock' && authState) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
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
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) => const AddExpenseScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => ExpenseDetailScreen(
                  id: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) => AddExpenseScreen(
                      editId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/income',
            builder: (_, __) => const IncomeScreen(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) => const AddIncomeScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => AddIncomeScreen(
                  editId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/wallets',
            builder: (_, __) => const WalletsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => AddWalletScreen(
                  wallet: state.extra as Wallet?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/folders',
            builder: (_, __) => const FoldersScreen(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => AddFolderScreen(
                  extra: state.extra,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/loans',
            builder: (_, __) => const LoansScreen(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) => const AddLoanScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => LoanDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/budgets',
            builder: (_, __) => const BudgetsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => AddBudgetScreen(
                  editBudget: state.extra as Budget?,
                ),
              ),
            ],
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
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => AddContactScreen(
                  editContact: state.extra as Contact?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/groups',
            builder: (_, __) => const GroupsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => AddGroupScreen(
                  editGroup: state.extra as SplitGroup?,
                ),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, state) => GroupDetailScreen(
                  groupId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/insights',
            builder: (_, __) => const InsightsScreen(),
          ),
          GoRoute(
            path: '/ocr',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, __) => const OcrScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'theme',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) => const ThemeSettingsScreen(),
              ),
              GoRoute(
                path: 'language',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) => const LanguageSettingsScreen(),
              ),
              GoRoute(
                path: 'security',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) => const SecuritySettingsScreen(),
              ),
              GoRoute(
                path: 'backup',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) => const BackupSettingsScreen(),
              ),
              GoRoute(
                path: 'profile',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (_, __) => const ProfileSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
