# Architecture: State Management (Riverpod)

Patterns, conventions, and provider map for the entire app.

---

## Why Riverpod

| Need | Solution |
|------|----------|
| Async DB reads | `FutureProvider` / `AsyncNotifierProvider` |
| Reactive lists | `StreamProvider` over SQLite streams |
| Global state (theme, auth) | `NotifierProvider` |
| Derived/computed values | `Provider` (synchronous derived) |
| Scoped state (forms) | `StateProvider` inside widget subtree |
| Parameterized providers | `family` modifier |

---

## Provider Naming Convention

```
<feature><DataType>Provider

Examples:
  expensesProvider               → FutureProvider<List<Expense>>
  walletBalanceProvider          → FutureProvider.family<double, String>
  dashboardSummaryProvider       → FutureProvider<DashboardSummary>
  isAuthenticatedProvider        → StateProvider<bool>
  themeProvider                  → NotifierProvider<ThemeNotifier, ThemeMode>
```

---

## Layer Architecture

```
UI Widgets
    │  (watch / read)
    ▼
Riverpod Providers
    │  (call methods on)
    ▼
Repository Layer
    │  (SQL queries via)
    ▼
DatabaseHelper (sqflite)
    │
    ▼
SQLite File
```

---

## Global Providers

### App Initialization
```dart
// Runs once on launch; resolves routing decision
final appInitProvider = FutureProvider<AppInitResult>((ref) async {
  await DatabaseHelper.instance.initialize();
  final profile = await ref.read(userProfileRepoProvider).getProfile();
  final security = await ref.read(securityRepoProvider).getSettings();
  return AppInitResult(isFirstTime: profile == null, hasPIN: security != null);
});
```

### Authentication
```dart
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

final securitySettingsProvider = FutureProvider<SecuritySettings?>((ref) {
  return ref.read(securityRepoProvider).getSettings();
});
```

### Theme
```dart
class ThemeNotifier extends Notifier<ThemeMode> {
  @override ThemeMode build() => ThemeMode.system;

  void setTheme(ThemeMode mode) {
    state = mode;
    ref.read(userProfileRepoProvider).updateTheme(mode.name);
  }
}
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
```

### User Profile
```dart
final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new
);
```

---

## Feature Providers

### Wallets
```dart
final walletsProvider = FutureProvider<List<Wallet>>((ref) {
  return ref.read(walletRepoProvider).getActiveWallets();
});

final walletBalanceProvider = FutureProvider.family<double, String>((ref, walletId) {
  return ref.read(walletRepoProvider).getWalletBalance(walletId);
});

final totalBalanceProvider = FutureProvider<double>((ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  final balances = await Future.wait(
    wallets.map((w) => ref.read(walletBalanceProvider(w.id).future))
  );
  return balances.fold(0.0, (a, b) => a + b);
});
```

### Expenses
```dart
@immutable
class ExpenseFilter {
  final DateTime? from;
  final DateTime? to;
  final String? folderId;
  final String? walletId;
  final String? category;
  const ExpenseFilter({...});
}

final expensesProvider = FutureProvider.family<List<Expense>, ExpenseFilter>(
  (ref, filter) => ref.read(expenseRepoProvider).getExpenses(filter: filter)
);

final todayExpenseTotalProvider = FutureProvider<double>((ref) {
  final today = DateTime.now();
  return ref.read(expenseRepoProvider).getTotalForPeriod(
    from: DateTime(today.year, today.month, today.day),
    to: today,
  );
});

final monthExpenseTotalProvider = FutureProvider<double>((ref) {
  final now = DateTime.now();
  return ref.read(expenseRepoProvider).getTotalForPeriod(
    from: DateTime(now.year, now.month, 1),
    to: now,
  );
});
```

### Dashboard
```dart
final recentTransactionsProvider = FutureProvider<List<Transaction>>((ref) {
  // unified view of last 10 expenses + income, sorted by date
  return ref.read(transactionRepoProvider).getRecent(limit: 10);
});

final dashboardProvider = FutureProvider<DashboardSummary>((ref) async {
  final results = await Future.wait([
    ref.watch(todayExpenseTotalProvider.future),
    ref.watch(monthExpenseTotalProvider.future),
    ref.watch(monthIncomeTotalProvider.future),
    ref.watch(walletsProvider.future),
    ref.watch(pendingLoansProvider.future),
    ref.watch(budgetAlertsProvider.future),
    ref.watch(recentTransactionsProvider.future),
  ]);
  return DashboardSummary.fromResults(results);
});
```

### Loans
```dart
final loansProvider = FutureProvider<List<Loan>>((ref) {
  return ref.read(loanRepoProvider).getAllLoans();
});

final pendingLoansProvider = FutureProvider<PendingLoanSummary>((ref) async {
  final active = await ref.read(loanRepoProvider).getActiveLoans();
  final overdue = await ref.read(loanRepoProvider).getOverdueLoans();
  return PendingLoanSummary(active: active, overdue: overdue);
});
```

### Search
```dart
final searchQueryProvider = StateProvider<String>((ref) => '');

// Debounced via custom extension
final searchResultsProvider = FutureProvider<SearchResults>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.length < 2) return Future.value(SearchResults.empty());
  return ref.read(searchRepoProvider).search(query);
});
```

### Sync
```dart
final unsyncedCountProvider = StreamProvider<int>((ref) {
  return ref.read(syncRepoProvider).watchUnsyncedCount();
});

final syncStatusProvider = NotifierProvider<SyncNotifier, SyncStatus>(SyncNotifier.new);
```

---

## Provider Invalidation Strategy

Whenever a write operation is performed, invalidate downstream providers:

```dart
// In ExpenseNotifier.addExpense():
Future<void> addExpense(Expense e) async {
  await ref.read(expenseRepoProvider).createExpense(e);
  ref.invalidate(expensesProvider);
  ref.invalidate(todayExpenseTotalProvider);
  ref.invalidate(monthExpenseTotalProvider);
  ref.invalidate(walletBalanceProvider(e.walletId));
  ref.invalidate(dashboardProvider);
  ref.invalidate(budgetAlertsProvider);  // check budget thresholds
}
```

**Invalidation map:**

| Write | Invalidates |
|-------|-------------|
| Add/Edit/Delete expense | `expensesProvider`, `todayExpenseTotalProvider`, `monthExpenseTotalProvider`, `walletBalanceProvider`, `dashboardProvider`, `budgetAlertsProvider` |
| Add/Edit/Delete income | `incomeProvider`, `monthIncomeTotalProvider`, `walletBalanceProvider`, `dashboardProvider` |
| Add/Edit wallet | `walletsProvider`, `totalBalanceProvider`, `dashboardProvider` |
| Add/Edit loan | `loansProvider`, `pendingLoansProvider`, `dashboardProvider` |
| Add budget | `budgetsProvider`, `budgetAlertsProvider` |
| Add group transaction | `groupsProvider`, `groupDetailProvider` |

---

## Repository Providers (DI)

```dart
// Each repo is a Provider so it can be overridden in tests
final expenseRepoProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(db: DatabaseHelper.instance);
});

final walletRepoProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(db: DatabaseHelper.instance);
});
// ... same pattern for all 15+ repos
```

---

## Error Handling Pattern

All async providers use `AsyncValue` pattern:

```dart
// In widget:
final wallets = ref.watch(walletsProvider);

return wallets.when(
  data: (list) => WalletList(wallets: list),
  loading: () => const WalletListShimmer(),
  error: (e, st) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(walletsProvider)),
);
```

Never use `.value!` (throws on null) or `.requireValue` (throws on error/loading).

---

## Form State Pattern

For Add/Edit screens use local `StateNotifier` scoped to the route:

```dart
class AddExpenseNotifier extends StateNotifier<AddExpenseState> {
  AddExpenseNotifier() : super(AddExpenseState.initial());

  void setAmount(String v) => state = state.copyWith(amount: double.tryParse(v));
  void setCategory(String c) => state = state.copyWith(category: c);
  void setDate(DateTime d) => state = state.copyWith(date: d);
  // ...
  bool get isValid => state.amount != null && state.amount! > 0 && state.category.isNotEmpty;
}

final addExpenseProvider = StateNotifierProvider.autoDispose<AddExpenseNotifier, AddExpenseState>(
  (_) => AddExpenseNotifier()
);
// autoDispose: cleans up when leaving the screen
```
