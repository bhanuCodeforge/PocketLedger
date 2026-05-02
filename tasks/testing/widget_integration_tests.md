# Testing: Widget & Integration Tests

---

## Widget Tests

Widget tests use `flutter_test` with a `ProviderScope` and mocked providers.

### Pattern
```dart
Widget buildTestWidget(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}
```

---

### PINLockScreen Tests
```dart
group('PINLockScreen', () {
  testWidgets('shows 6 empty pin dots initially', (tester) async {
    await tester.pumpWidget(buildTestWidget(const PINLockScreen()));
    expect(find.byKey(const Key('pin_dot_empty')), findsNWidgets(6));
  });

  testWidgets('tapping 6 digits fills all dots', (tester) async {
    await tester.pumpWidget(buildTestWidget(const PINLockScreen()));
    for (int i = 1; i <= 6; i++) {
      await tester.tap(find.text('$i'));
      await tester.pump();
    }
    expect(find.byKey(const Key('pin_dot_filled')), findsNWidgets(6));
  });

  testWidgets('wrong PIN shows error and clears input', (tester) async {
    // override securityProvider to return a known hash
    await tester.pumpWidget(buildTestWidget(const PINLockScreen(), overrides: [...]));
    // Enter wrong PIN
    for (int i = 0; i < 6; i++) await tester.tap(find.text('0'));
    await tester.pump();
    expect(find.text('Incorrect PIN'), findsOneWidget);
    expect(find.byKey(const Key('pin_dot_empty')), findsNWidgets(6)); // cleared
  });

  testWidgets('backspace removes last digit', (tester) async { ... });
  testWidgets('biometric button shown when biometric_enabled = 1', (tester) async { ... });
  testWidgets('5 wrong attempts shows recovery link', (tester) async { ... });
});
```

---

### AddExpenseScreen Tests
```dart
group('AddExpenseScreen', () {
  testWidgets('save disabled when amount is empty', (tester) async {
    await tester.pumpWidget(buildTestWidget(const AddExpenseScreen(), overrides: [
      walletsProvider.overrideWith((_) async => [Fixtures.wallet()]),
    ]));
    final saveButton = find.byKey(const Key('save_expense_button'));
    expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNull);
  });

  testWidgets('entering amount enables save button', (tester) async {
    await tester.pumpWidget(...);
    await tester.enterText(find.byKey(const Key('amount_field')), '250');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(find.byKey(const Key('save_expense_button'))).onPressed, isNotNull);
  });

  testWidgets('category selector shows all categories', (tester) async {
    await tester.pumpWidget(...);
    await tester.tap(find.byKey(const Key('category_selector')));
    await tester.pumpAndSettle();
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Medical'), findsOneWidget);
    expect(find.text('Fuel'), findsOneWidget);
  });

  testWidgets('submitting valid form calls createExpense', (tester) async {
    final mockRepo = MockExpenseRepository();
    await tester.pumpWidget(...);
    // fill in form, tap save
    verify(() => mockRepo.createExpense(any())).called(1);
  });
});
```

---

### Dashboard Tests
```dart
group('DashboardScreen', () {
  testWidgets('shows today expense total', (tester) async {
    await tester.pumpWidget(buildTestWidget(const DashboardScreen(), overrides: [
      todayExpenseTotalProvider.overrideWith((_) async => 450.0),
      monthExpenseTotalProvider.overrideWith((_) async => 3200.0),
      walletsProvider.overrideWith((_) async => [Fixtures.wallet()]),
      recentTransactionsProvider.overrideWith((_) async => []),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('₹450.00'), findsOneWidget);
  });

  testWidgets('shimmer shown while loading', (tester) async {
    await tester.pumpWidget(buildTestWidget(const DashboardScreen(), overrides: [
      dashboardProvider.overrideWith((_) async {
        await Future.delayed(const Duration(seconds: 10));
        return DashboardSummary.empty();
      }),
    ]));
    await tester.pump(); // first frame
    expect(find.byType(ShimmerWidget), findsWidgets);
  });

  testWidgets('error state shows retry button', (tester) async { ... });
});
```

---

### BudgetProgressBar Tests
```dart
group('BudgetProgressBar', () {
  testWidgets('green when under 50%', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BudgetProgressBar(spent: 40, total: 100),
    ));
    final progressBar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(progressBar.color, Colors.green);
  });

  testWidgets('orange between 50% and 79%', (tester) async { ... });
  testWidgets('red at 80%+', (tester) async { ... });
  testWidgets('shows correct percentage text', (tester) async { ... });
});
```

---

## Integration Tests

Run on real device or emulator using `integration_test` package.

### Setup
```dart
// integration_test/helpers/app_driver.dart
Future<void> launchApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));
}
```

---

### Flow 1: Onboarding → First Expense
```dart
testWidgets('complete onboarding and add first expense', (tester) async {
  await launchApp(tester);

  // Welcome screen
  expect(find.text('Welcome to PocketLedger'), findsOneWidget);
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();

  // Currency selection
  await tester.tap(find.text('INR (₹)'));
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();

  // Create wallet
  await tester.enterText(find.byKey(const Key('wallet_name')), 'Cash');
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();

  // Set PIN
  for (int d in [1,2,3,4,5,6]) await tester.tap(find.text('$d'));
  await tester.pumpAndSettle();
  for (int d in [1,2,3,4,5,6]) await tester.tap(find.text('$d')); // confirm
  await tester.pumpAndSettle();

  // Dashboard
  expect(find.byType(DashboardScreen), findsOneWidget);

  // Add expense
  await tester.tap(find.byKey(const Key('fab_add_expense')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('amount_field')), '150');
  await tester.tap(find.text('Food'));
  await tester.tap(find.byKey(const Key('save_expense_button')));
  await tester.pumpAndSettle();

  // Back on dashboard — today total updated
  expect(find.text('₹150.00'), findsOneWidget);
});
```

---

### Flow 2: Expense CRUD (Edit & Delete)
```dart
testWidgets('edit and delete an expense', (tester) async {
  // Pre-seed DB with an expense
  // Launch → tap expense → edit → change amount → save → verify new amount
  // Delete → confirm → verify removed from list
});
```

---

### Flow 3: Loan Payment Flow
```dart
testWidgets('add loan, make partial payment, check remaining', (tester) async {
  // Create contact
  // Create loan: given, ₹5000, 10%, simple, 1yr
  // Verify total due shown ≈ ₹5500
  // Add payment ₹2000
  // Verify remaining due ≈ ₹3500
  // Mark settled (pay remaining)
  // Verify status = Settled
});
```

---

### Flow 4: Group Split
```dart
testWidgets('create group, add expense, verify balances', (tester) async {
  // Create group: Trip Goa, 3 members (You, Alice, Bob)
  // Add expense: ₹3000, paid by You, equal split
  // Verify each member owes ₹1000
  // Verify "You" balance = +₹2000 (others owe you)
  // Mark Alice settled
  // Verify balance updated
});
```

---

### Flow 5: Backup & Restore Round-Trip
```dart
testWidgets('backup to Drive and restore', (tester) async {
  // Sign in with test Google account
  // Add 3 expenses
  // Tap Backup Now → wait for completion
  // Verify backup file appears in Drive
  // Clear local DB (simulate new device)
  // Tap Restore → select backup → enter PIN
  // Verify all 3 expenses restored
});
```

---

### Flow 6: PIN Lock & Biometric
```dart
testWidgets('app locks after configured idle time', (tester) async {
  // Complete onboarding, set PIN
  // Set lock_after_minutes = 0 (immediate)
  // Background and foreground app
  // Verify PIN lock screen shown
  // Enter correct PIN → dashboard
  // Enter wrong PIN × 5 → recovery shown
});
```
