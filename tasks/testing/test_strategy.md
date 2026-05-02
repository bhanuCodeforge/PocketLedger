# Testing: Overall Test Strategy

Covers test philosophy, tooling, coverage targets, and CI integration for PocketLedger.

---

## Testing Philosophy

| Layer | Tool | Goal |
|-------|------|-------|
| Business logic, calculators, parsers | `flutter_test` (unit) | 90%+ coverage |
| Repository / DB queries | `flutter_test` + in-memory SQLite | All queries verified |
| Riverpod providers | `riverpod_test` | All state transitions |
| Widgets & screens | `flutter_test` widget tests | Key flows |
| Critical user journeys | `integration_test` | End-to-end on device |

---

## Test Folder Structure

```
test/
├── unit/
│   ├── calculators/
│   │   ├── loan_calculator_test.dart
│   │   ├── split_calculator_test.dart
│   │   └── currency_formatter_test.dart
│   ├── parsers/
│   │   ├── receipt_parser_test.dart
│   │   └── sms_parser_test.dart
│   ├── repositories/
│   │   ├── expense_repository_test.dart
│   │   ├── income_repository_test.dart
│   │   ├── loan_repository_test.dart
│   │   ├── wallet_repository_test.dart
│   │   ├── folder_repository_test.dart
│   │   ├── budget_repository_test.dart
│   │   ├── contact_repository_test.dart
│   │   └── group_repository_test.dart
│   ├── services/
│   │   ├── encryption_service_test.dart
│   │   ├── backup_service_test.dart
│   │   └── insight_engine_test.dart
│   └── models/
│       ├── expense_model_test.dart
│       └── loan_model_test.dart
├── widget/
│   ├── screens/
│   │   ├── dashboard_test.dart
│   │   ├── add_expense_test.dart
│   │   ├── loan_detail_test.dart
│   │   └── pin_lock_test.dart
│   └── components/
│       ├── amount_input_test.dart
│       ├── attachment_picker_test.dart
│       └── budget_progress_bar_test.dart
├── integration/
│   ├── onboarding_flow_test.dart
│   ├── expense_crud_test.dart
│   ├── loan_payment_flow_test.dart
│   ├── backup_restore_test.dart
│   └── group_split_flow_test.dart
└── helpers/
    ├── test_database.dart     ← in-memory SQLite setup
    ├── mock_repositories.dart ← Mockito mocks
    └── fixtures.dart          ← sample data builders
```

---

## Test Database Helper

```dart
// test/helpers/test_database.dart
class TestDatabase {
  static Future<Database> create() async {
    // Use sqflite_ffi for in-memory database in tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    return openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: DatabaseHelper.onCreate,
    );
  }
}
```

Repositories under test use this in-memory database — no mocking of DB layer.

---

## Riverpod Test Pattern

```dart
// Using ProviderContainer + override for isolation
test('todayExpenseTotalProvider returns correct sum', () async {
  final db = await TestDatabase.create();
  await db.insert('expenses', {...}); // seed

  final container = ProviderContainer(overrides: [
    expenseRepoProvider.overrideWithValue(ExpenseRepository(db: db)),
  ]);
  addTearDown(container.dispose);

  final total = await container.read(todayExpenseTotalProvider.future);
  expect(total, 250.0);
});
```

---

## Coverage Targets

| Component | Target |
|-----------|--------|
| `LoanCalculator` | 100% |
| `SplitCalculator` | 100% |
| `ReceiptParser` | 95% |
| `SMSParserService` | 95% |
| `InsightEngine` rules | 90% |
| All repositories | 85% |
| `EncryptionService` | 100% |
| Widget screens | 70% |
| Integration flows | 5 flows × happy path + 1 error path |

---

## CI Pipeline (GitHub Actions)

```yaml
name: Test & Analyze
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: 'stable' }
      - run: flutter pub get
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4
        with: { file: coverage/lcov.info }
```

---

## Test Data Fixtures

```dart
// test/helpers/fixtures.dart
class Fixtures {
  static Expense expense({
    String? id,
    double amount = 250.0,
    String category = 'food',
    String? walletId,
  }) => Expense(
    id: id ?? const Uuid().v4(),
    amount: amount,
    category: category,
    date: DateTime.now(),
    walletId: walletId ?? 'wallet-1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static Wallet wallet({String id = 'wallet-1', double openingBalance = 0.0}) =>
    Wallet(id: id, name: 'Test Wallet', type: WalletType.cash,
           openingBalance: openingBalance, ...);

  static Loan loan({double principal = 1000.0, double rate = 10.0}) =>
    Loan(id: const Uuid().v4(), contactId: 'contact-1', type: LoanType.given,
         principal: principal, interestRate: rate, ...);
}
```

---

## Mocking External Dependencies

Use `mocktail` for services that have external side effects:

- [ ] Mock `GoogleAuthService` → avoid real OAuth in tests
- [ ] Mock `DriveService` → avoid real Drive API calls
- [ ] Mock `NotificationService` → avoid scheduling real notifications
- [ ] Mock `AttachmentService.pickFromCamera()` → return fixture file

```dart
class MockDriveService extends Mock implements DriveService {}
```

---

## Running Tests

```bash
# All unit tests
flutter test test/unit/

# All widget tests
flutter test test/widget/

# Coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Integration tests (requires connected device/emulator)
flutter test integration_test/
```
