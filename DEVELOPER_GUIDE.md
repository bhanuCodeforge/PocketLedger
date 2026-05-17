# PocketLedger — Developer Guide

Complete reference for contributing to and extending the PocketLedger codebase.

---

## Table of Contents

1. [Environment Setup](#1-environment-setup)
2. [Architecture Overview](#2-architecture-overview)
3. [Database Layer](#3-database-layer)
4. [Adding a New Feature Module](#4-adding-a-new-feature-module)
5. [State Management Patterns](#5-state-management-patterns)
6. [Navigation & Routing](#6-navigation--routing)
7. [Theme & Styling](#7-theme--styling)
8. [Localization](#8-localization)
9. [Currency Formatting](#9-currency-formatting)
10. [Testing](#10-testing)
11. [VSCode Debugger Setup](#11-vscode-debugger-setup)
12. [Common Patterns & Recipes](#12-common-patterns--recipes)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Environment Setup

### Required tools

| Tool | Version | Install |
|------|---------|---------|
| Flutter SDK | ≥ 3.19 | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart | ≥ 3.3 (bundled) | — |
| Android Studio | ≥ 2023.x | For Android emulator + SDK |
| Xcode | ≥ 15 (macOS only) | App Store |
| VSCode | any | + Dart + Flutter extensions |

### First-time setup

```bash
cd pocket_ledger

# Install all pub dependencies
flutter pub get

# Generate localization files (REQUIRED — do this after any .arb change)
flutter gen-l10n

# Verify everything builds
flutter analyze
flutter test
```

### Rebuild after dependency changes

```bash
flutter pub get && flutter gen-l10n
```

### Run on a device

```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run with verbose logging
flutter run --verbose
```

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│  Presentation  (lib/features/*/presentation/)        │
│  ConsumerWidget / ConsumerStatefulWidget             │
│  ↕ ref.watch / ref.read                             │
├─────────────────────────────────────────────────────┤
│  State (Riverpod Providers)                          │
│  FutureProvider / StateNotifierProvider / Provider   │
│  lib/features/*/data/*_providers.dart               │
│  lib/shared/providers/                              │
├─────────────────────────────────────────────────────┤
│  Repository  (lib/features/*/data/*_repository.dart) │
│  extends BaseRepository → DatabaseHelper.instance   │
├─────────────────────────────────────────────────────┤
│  SQLite Database  (lib/core/database/)               │
│  DatabaseHelper singleton, WAL mode, FK ON           │
└─────────────────────────────────────────────────────┘
```

**Key principles:**
- **No business logic in widgets** — all computation in repositories or providers
- **Providers are the only dependency** widgets take; they never instantiate repositories directly
- **One DB singleton** — `DatabaseHelper.instance` — opened lazily on first access
- **All timestamps are milliseconds since epoch (int)**, not ISO strings

---

## 3. Database Layer

### DatabaseHelper

`lib/core/database/database_helper.dart`

```dart
// Access anywhere:
final database = await DatabaseHelper.instance.database;
```

- Opens `pocket_ledger.db` in the platform's documents directory
- Runs `_createTables` on first install (23 tables + indexes)
- Migrations go in `_onUpgrade` keyed by `oldVersion`
- WAL mode + foreign keys are enabled in `_onConfigure`

### BaseRepository

All repositories extend this:

```dart
abstract class BaseRepository {
  Future<Database> get db => DatabaseHelper.instance.database;
}
```

### Adding a migration

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE expenses ADD COLUMN receipt_url TEXT');
  }
  if (oldVersion < 3) {
    // next migration
  }
}
```

Bump `_dbVersion` from `1` to `2` simultaneously.

### Timestamp convention

All date/time fields stored as **milliseconds since epoch (int)**:
```dart
final now = DateTime.now().millisecondsSinceEpoch;
// Read back:
final dt = DateTime.fromMillisecondsSinceEpoch(row['expense_date'] as int);
```

---

## 4. Adding a New Feature Module

Follow this checklist to add a new feature (e.g. "Recurring Rules"):

### Step 1 — Model (`lib/features/recurring/data/recurring_rule.dart`)

```dart
class RecurringRule {
  final String id;
  final String frequency;   // 'daily' | 'weekly' | 'monthly'
  final int nextDueDate;    // ms epoch
  final int createdAt;
  final int updatedAt;

  const RecurringRule({
    required this.id,
    required this.frequency,
    required this.nextDueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringRule.fromMap(Map<String, dynamic> map) => RecurringRule(
    id: map['id'] as String,
    frequency: map['frequency'] as String,
    nextDueDate: map['next_due_date'] as int,
    createdAt: map['created_at'] as int,
    updatedAt: map['updated_at'] as int,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'frequency': frequency,
    'next_due_date': nextDueDate,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  RecurringRule copyWith({String? id, String? frequency, int? nextDueDate,
      int? createdAt, int? updatedAt}) => RecurringRule(
    id: id ?? this.id,
    frequency: frequency ?? this.frequency,
    nextDueDate: nextDueDate ?? this.nextDueDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
```

### Step 2 — Repository (`lib/features/recurring/data/recurring_rule_repository.dart`)

```dart
import 'package:uuid/uuid.dart';
import '../../../core/database/base_repository.dart';
import 'recurring_rule.dart';

class RecurringRuleRepository extends BaseRepository {
  static const _table = 'recurring_rules';

  Future<List<RecurringRule>> getActive() async {
    final database = await db;
    final rows = await database.query(
      _table,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'next_due_date ASC',
    );
    return rows.map(RecurringRule.fromMap).toList();
  }

  Future<String> create(RecurringRule rule) async {
    final database = await db;
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(_table, {
      ...rule.toMap(),
      'id': id,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  Future<void> update(RecurringRule rule) async {
    final database = await db;
    await database.update(
      _table,
      {...rule.toMap(), 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<void> delete(String id) async {
    final database = await db;
    await database.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
```

### Step 3 — Providers (`lib/features/recurring/data/recurring_rule_providers.dart`)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'recurring_rule.dart';
import 'recurring_rule_repository.dart';

final recurringRuleRepositoryProvider = Provider<RecurringRuleRepository>(
  (_) => RecurringRuleRepository(),
);

final activeRecurringRulesProvider = FutureProvider<List<RecurringRule>>((ref) {
  return ref.watch(recurringRuleRepositoryProvider).getActive();
});
```

### Step 4 — Screen (`lib/features/recurring/presentation/recurring_screen.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/recurring_rule_providers.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(activeRecurringRulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Rules')),
      body: rulesAsync.when(
        data: (rules) => rules.isEmpty
            ? const Center(child: Text('No recurring rules'))
            : ListView.builder(
                itemCount: rules.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(rules[i].frequency),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
```

### Step 5 — Register route in `app_router.dart`

```dart
import '../../features/recurring/presentation/recurring_screen.dart';

// Inside ShellRoute routes:
GoRoute(
  path: '/recurring',
  builder: (_, __) => const RecurringScreen(),
),
```

### Step 6 — Add l10n strings to `lib/l10n/app_en.arb`

```json
"recurringTitle": "Recurring Rules",
"recurringAdd": "Add Rule",
```

Run `flutter gen-l10n` after editing.

---

## 5. State Management Patterns

### Reading async data in a widget

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(someProvider);
    return dataAsync.when(
      data: (data) => Text(data.toString()),
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => Text('Error: $e'),
    );
  }
}
```

### Refreshing a provider after a write

```dart
// After insert/update/delete:
ref.invalidate(expensesProvider);
ref.invalidate(todayExpenseTotalProvider);
```

### Family providers (parameterized)

```dart
// Declaration:
final loanPaymentsProvider = FutureProvider.family<List<LoanPayment>, String>(
  (ref, loanId) => ref.watch(loanRepositoryProvider).getPayments(loanId),
);

// Usage:
final payments = ref.watch(loanPaymentsProvider(loan.id));
```

### One-shot async operation (button tap)

```dart
Future<void> _save() async {
  final repo = ref.read(expenseRepositoryProvider);
  await repo.create(expense);
  ref.invalidate(expensesProvider);
  if (mounted) context.pop();
}
```

> Use `ref.read` (not `ref.watch`) inside event handlers. `ref.watch` is only for `build`.

### currencyProvider usage

```dart
// currencyProvider is a synchronous Provider<Map<String, String>>
final currency = ref.watch(currencyProvider);
// currency['symbol'] → '₹', currency['code'] → 'INR'

final formatted = CurrencyFormatter.formatAmount(amount, currency);
// or:
final formatted = CurrencyFormatter.formatSimple(amount, currency['symbol']!);
```

---

## 6. Navigation & Routing

### Push a new route (adds to back stack)

```dart
context.push('/expenses/add');
context.push('/loans/${loan.id}');
```

### Replace current route

```dart
context.go('/dashboard');
```

### Pop with a result

```dart
context.pop(true); // signals success to caller
```

### Pass objects via `extra`

```dart
// Push with extra:
context.push('/wallets/add', extra: wallet); // passing a Wallet

// Router receives it:
GoRoute(
  path: 'add',
  builder: (_, state) => AddWalletScreen(wallet: state.extra as Wallet?),
),
```

### Navigate to modal (uses rootNavigatorKey so it overlays the shell)

```dart
GoRoute(
  path: 'add',
  parentNavigatorKey: _rootNavigatorKey,  // <-- this key
  builder: (_, __) => const AddExpenseScreen(),
),
```

---

## 7. Theme & Styling

### Using AppColors

```dart
import 'package:pocket_ledger/core/theme/app_colors.dart';

Container(color: AppColors.income)     // green for income
Container(color: AppColors.expense)    // red for expense
Container(color: AppColors.primary)    // brand blue
Container(color: AppColors.warning)    // amber for alerts
```

### Theme-adaptive color

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
```

### Material 3 color scheme

```dart
final scheme = Theme.of(context).colorScheme;
scheme.primary        // brand color
scheme.onSurface      // text color
scheme.surfaceContainerHighest  // card background
```

### Category colors map

```dart
final Map<String, Color> categoryColors = {
  'food': AppColors.catFood,
  'grocery': AppColors.catGrocery,
  'fuel': AppColors.catFuel,
  'rent': AppColors.catRent,
  'medical': AppColors.catMedical,
  'shopping': AppColors.catShopping,
  'travel': AppColors.catTravel,
  'entertainment': AppColors.catEntertainment,
  'education': AppColors.catEducation,
  'utilities': AppColors.catUtilities,
  'other': AppColors.catOther,
};
```

---

## 8. Localization

### Using l10n in a widget

```dart
import 'package:pocket_ledger/generated/l10n/app_localizations.dart';

final l10n = AppLocalizations.of(context);
Text(l10n.expenseTitle)
Text(l10n.lockWrongPin(remaining: 3))   // parameterized
```

### Adding a new string

1. Edit `lib/l10n/app_en.arb`:
   ```json
   "myNewKey": "My new text",
   "@myNewKey": { "description": "Used on the X screen" }
   ```
2. Add the same key to `app_hi.arb` and `app_ar.arb` with translations
3. Run `flutter gen-l10n`
4. Use: `AppLocalizations.of(context).myNewKey`

### Parameterized strings

```arb
"itemCount": "{count} items",
"@itemCount": {
  "placeholders": {
    "count": { "type": "int" }
  }
}
```

Usage: `l10n.itemCount(count: 5)`

---

## 9. Currency Formatting

```dart
import 'package:pocket_ledger/core/utils/currency_formatter.dart';

// Using currencyProvider (preferred in widgets):
final currency = ref.watch(currencyProvider); // Map<String, String>
CurrencyFormatter.formatAmount(1234.5, currency)  // → '₹1234.50'

// Using just a symbol:
CurrencyFormatter.formatSimple(1234.5, '₹')  // → '₹1234.50'

// Using full UserProfile (respects JPY/KRW no-decimal rule):
CurrencyFormatter.format(1234.5, profile)

// Compact (for chart labels):
CurrencyFormatter.compact(1500000.0, '₹')  // → '₹1.5M'
```

---

## 10. Testing

### Test structure

```
test/
├── database_helper_test.dart    # SQLite schema + basic CRUD
└── theme_test.dart              # Light/dark ThemeData sanity

integration_test/
├── onboarding_flow_test.dart    # First launch → dashboard
├── expense_flow_test.dart       # Add/edit/delete expense
├── loan_flow_test.dart          # Loan + payment + settle
└── backup_flow_test.dart        # Local backup creation
```

### Running tests

```bash
# Unit tests
flutter test

# Single file
flutter test test/database_helper_test.dart

# Integration (device required)
flutter test integration_test/expense_flow_test.dart

# All integration tests
flutter test integration_test/
```

### Writing a unit test for a repository

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pocket_ledger/core/database/database_helper.dart';
import 'package:pocket_ledger/features/expenses/data/expense_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Fresh in-memory DB per test
    await DatabaseHelper.instance.close();
  });

  test('creates and retrieves an expense', () async {
    final repo = ExpenseRepository();
    final id = await repo.create(Expense(
      id: '',
      walletId: 'wallet-1',
      amount: 100.0,
      category: 'food',
      paymentMode: 'cash',
      note: 'Test',
      expenseDate: DateTime.now().millisecondsSinceEpoch,
      isRecurring: false,
      createdAt: 0,
      updatedAt: 0,
    ));

    final retrieved = await repo.getById(id);
    expect(retrieved, isNotNull);
    expect(retrieved!.amount, 100.0);
  });
}
```

### Using `mocktail` for provider mocks in widget tests

```dart
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

testWidgets('ExpensesScreen shows empty state', (tester) async {
  final mockRepo = MockExpenseRepository();
  when(() => mockRepo.getAll()).thenAnswer((_) async => []);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      expenseRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: const MaterialApp(home: ExpensesScreen()),
  ));

  await tester.pumpAndSettle();
  expect(find.text('No data found'), findsOneWidget);
});
```

---

## 11. VSCode Debugger Setup

The `.vscode/` directory is included in the repo with pre-configured launch configs.

### Available launch configurations

| Config | Description |
|--------|-------------|
| `PocketLedger (debug)` | Hot-reload debug session |
| `PocketLedger (profile)` | Performance profiling |
| `PocketLedger (release)` | Release build on device |
| `Tests (all)` | Run all unit tests with coverage |
| `Tests: database_helper_test.dart` | Run DB tests only |
| `Integration: full onboarding flow` | E2E: first launch |
| `Integration: expense CRUD` | E2E: add/edit/delete expense |
| `Integration: loan + payment` | E2E: loan lifecycle |
| `Integration: backup + restore` | E2E: backup creation |

### Start a debug session

1. Open the project in VSCode: `code .` (inside `pocket_ledger/`)
2. Connect a device or start an emulator
3. Press **F5** or open *Run → Start Debugging*
4. Select **"PocketLedger (debug)"** from the dropdown

### Available VSCode tasks (Ctrl+Shift+P → "Run Task")

| Task | Action |
|------|--------|
| `flutter: pub get` | Install dependencies |
| `flutter: gen-l10n` | Regenerate localization |
| `flutter: analyze` | Run static analysis |
| `flutter: test` | Run all tests + coverage |
| `flutter: build apk (debug)` | Build debug APK |
| `flutter: build apk (release)` | Build release APK |
| `flutter: build appbundle` | Build Play Store bundle |
| `flutter: clean + pub get` | Full clean rebuild |
| `flutter: full setup` | pub get + l10n + icons + splash |

### Breakpoint debugging tips

- Set breakpoints in repository methods to inspect DB queries
- Use **Debug Console** to evaluate expressions: `ref.read(expensesProvider.future)`
- Enable **Flutter Inspector** (sidebar) to inspect widget trees
- Use **DevTools** (Ctrl+Shift+P → "Open DevTools") for:
  - Widget tree inspector
  - Performance timeline
  - Memory profiler
  - Network requests (for Google Drive calls)

### Hot reload vs hot restart

| Action | Shortcut | When to use |
|--------|----------|-------------|
| Hot reload | `r` in terminal / save file | UI changes, most Dart changes |
| Hot restart | `R` in terminal | Provider state changes, new DB tables |
| Full restart | Stop + start | Platform channel changes, native code |

---

## 12. Common Patterns & Recipes

### Date grouping (Today / Yesterday / date)

```dart
String _dateLabel(int timestampMs) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));
  if (_sameDay(date, today)) return 'Today';
  if (_sameDay(date, yesterday)) return 'Yesterday';
  return DateFormat('dd MMM yyyy').format(date);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
```

### Swipe to delete with confirmation

```dart
Dismissible(
  key: Key(item.id),
  direction: DismissDirection.endToStart,
  confirmDismiss: (_) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
  },
  onDismissed: (_) async {
    await ref.read(expenseRepositoryProvider).delete(item.id);
    ref.invalidate(expensesProvider);
  },
  background: Container(
    color: AppColors.expense,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 16),
    child: const Icon(Icons.delete, color: Colors.white),
  ),
  child: MyListTile(item: item),
)
```

### Show loading + save button

```dart
bool _loading = false;

ElevatedButton(
  onPressed: _loading ? null : _save,
  child: _loading
      ? const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2))
      : const Text('Save'),
)

Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _loading = true);
  try {
    await ref.read(expenseRepositoryProvider).create(expense);
    ref.invalidate(expensesProvider);
    if (mounted) context.pop();
  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
```

### Empty state widget

```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.receipt_long_outlined, size: 64,
           color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
      const SizedBox(height: 16),
      Text(l10n.noData,
           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
           )),
    ],
  ),
)
```

### Amount input field

```dart
TextFormField(
  controller: _amountController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
  ],
  decoration: InputDecoration(
    prefixText: currency['symbol'],
    hintText: '0.00',
    labelText: l10n.amount,
  ),
  validator: (v) {
    if (v == null || v.isEmpty) return l10n.required;
    final amount = double.tryParse(v);
    if (amount == null || amount <= 0) return l10n.errorInvalidAmount;
    return null;
  },
)
```

---

## 13. Troubleshooting

### `flutter gen-l10n` fails

- Ensure `l10n.yaml` exists at project root
- All `.arb` files must be valid JSON
- All keys used in Dart must exist in `app_en.arb`
- Run `flutter pub get` first

### DB column not found at runtime

1. The column exists in `database_helper.dart` `_createTables` but only takes effect on fresh install
2. For development: uninstall the app from the device to wipe the DB, then reinstall
3. For production: add a migration in `_onUpgrade` and bump `_dbVersion`

### Provider not refreshing after write

Always call `ref.invalidate(providerName)` after any write operation.  
If data still stale, check if you're watching `FutureProvider` (not a `StateProvider`).

### GoRouter redirect loop

Check the redirect function in `routerProvider`. Common causes:
- `appInit.isLoading` stays true → DB init failed silently
- `authState` never becomes `true` → `authStateProvider` not set after PIN entry

Debug: add `debugLogDiagnostics: true` to `GoRouter(...)` and watch console output.

### Wallet balance always shows 0

The balance is computed via `getWalletBalance` which runs a SQL query joining `income` and `expenses` tables. Ensure:
- Expenses have `wallet_id` set correctly
- The wallet's `is_archived` field is 0 (not archived)

### Integration tests flaky

- Increase `pumpAndSettle` timeout for slow emulators: `pumpAndSettle(const Duration(seconds: 5))`
- Use `find.byKey(Key('widget_key'))` for reliable targeting instead of text finders

### `flutter analyze` warnings about unused imports

Run `dart fix --apply` to auto-remove unused imports.

---

*Last updated: May 2026*
