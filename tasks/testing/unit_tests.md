# Testing: Unit Tests

Detailed test cases for every business-logic class. No UI involved.

---

## LoanCalculator Tests

```dart
// test/unit/calculators/loan_calculator_test.dart
group('LoanCalculator', () {

  group('simpleInterest', () {
    test('zero rate returns zero interest', () {
      expect(LoanCalculator.simpleInterest(1000, 0, 1), 0.0);
    });
    test('basic SI: P=1000, R=10%, T=1yr → SI=100', () {
      expect(LoanCalculator.simpleInterest(1000, 10, 1), 100.0);
    });
    test('fractional year: 6 months → SI=50', () {
      expect(LoanCalculator.simpleInterest(1000, 10, 0.5), 50.0);
    });
    test('large principal', () {
      expect(LoanCalculator.simpleInterest(100000, 12, 2), 24000.0);
    });
  });

  group('compoundAmount', () {
    test('zero rate returns principal', () {
      expect(LoanCalculator.compoundAmount(1000, 0, 12, 1), 1000.0);
    });
    test('P=1000, r=10%, n=12, t=1 → ~1104.71', () {
      expect(
        LoanCalculator.compoundAmount(1000, 10, 12, 1),
        closeTo(1104.71, 0.01),
      );
    });
    test('P=500, r=8%, n=4, t=2 → ~584.93', () {
      expect(
        LoanCalculator.compoundAmount(500, 8, 4, 2),
        closeTo(584.93, 0.01),
      );
    });
    test('n=1 (annual compounding)', () {
      expect(
        LoanCalculator.compoundAmount(1000, 10, 1, 1),
        closeTo(1100.0, 0.01),
      );
    });
  });

  group('totalDue', () {
    test('no payments → total due = principal + interest', () {
      final loan = Fixtures.loan(principal: 1000, rate: 10);
      // 1 year elapsed
      final due = LoanCalculator.totalDue(loan, [], yearsElapsed: 1.0);
      expect(due, closeTo(1100.0, 1.0)); // SI
    });
    test('partial payment reduces due', () {
      final loan = Fixtures.loan(principal: 1000, rate: 0);
      final payment = LoanPayment(amount: 300, ...);
      expect(LoanCalculator.totalDue(loan, [payment], yearsElapsed: 0), 700.0);
    });
    test('fully paid loan returns 0 or negative (overpaid)', () {
      final loan = Fixtures.loan(principal: 1000, rate: 0);
      final payments = [LoanPayment(amount: 1000, ...)];
      expect(LoanCalculator.totalDue(loan, payments, yearsElapsed: 0), 0.0);
    });
  });
});
```

---

## SplitCalculator Tests

```dart
group('SplitCalculator', () {

  group('equalSplit', () {
    test('divisible evenly', () {
      expect(SplitCalculator.equalSplit(300, 3), [100.0, 100.0, 100.0]);
    });
    test('indivisible — remainder goes to first member', () {
      final splits = SplitCalculator.equalSplit(100, 3);
      expect(splits.reduce((a, b) => a + b), closeTo(100.0, 0.01));
      // First share gets the extra penny
      expect(splits[0], greaterThanOrEqualTo(splits[1]));
    });
    test('single member gets full amount', () {
      expect(SplitCalculator.equalSplit(500, 1), [500.0]);
    });
    test('zero amount', () {
      expect(SplitCalculator.equalSplit(0, 3), [0.0, 0.0, 0.0]);
    });
  });

  group('customSplit', () {
    test('valid split passes', () {
      expect(() => SplitCalculator.validateCustom([100, 150, 50], 300), returnsNormally);
    });
    test('amounts not summing to total throws', () {
      expect(() => SplitCalculator.validateCustom([100, 100], 300), throwsA(isA<SplitValidationError>()));
    });
    test('negative amount throws', () {
      expect(() => SplitCalculator.validateCustom([-50, 350], 300), throwsA(isA<SplitValidationError>()));
    });
  });

  group('percentageSplit', () {
    test('100% sums correctly', () {
      final splits = SplitCalculator.percentageSplit(300, [50, 30, 20]);
      expect(splits, [150.0, 90.0, 60.0]);
    });
    test('percentages not summing to 100 throws', () {
      expect(() => SplitCalculator.percentageSplit(300, [50, 30]), throwsA(isA<SplitValidationError>()));
    });
  });
});
```

---

## ReceiptParser Tests

```dart
group('ReceiptParser', () {

  test('extracts total amount with "Total:" prefix', () {
    final text = 'CAFÉ MOCHA\nTotal: ₹ 285.50\nThank you';
    final result = ReceiptParser.parse(text);
    expect(result.amount, 285.50);
  });

  test('extracts amount with "Rs." prefix', () {
    final text = 'Grand Total Rs.1,234.00';
    expect(ReceiptParser.parse(text).amount, 1234.0);
  });

  test('extracts largest amount when no label found', () {
    final text = 'Item 1: 50\nItem 2: 75\nGST: 11.25\n136.25';
    expect(ReceiptParser.parse(text).amount, 136.25);
  });

  test('parses DD/MM/YYYY date', () {
    final text = 'Date: 15/04/2026\nTotal: ₹500';
    expect(ReceiptParser.parse(text).date, DateTime(2026, 4, 15));
  });

  test('rejects future date', () {
    final text = 'Date: 31/12/2027\nTotal: ₹100';
    expect(ReceiptParser.parse(text).date, isNull);
  });

  test('suggests Food category for restaurant keywords', () {
    final text = 'PIZZA HUT RESTAURANT\nTotal: ₹750';
    expect(ReceiptParser.parse(text).suggestedCategory, 'food');
  });

  test('returns null amounts when nothing parseable', () {
    final text = 'No numbers here at all.';
    expect(ReceiptParser.parse(text).amount, isNull);
  });
});
```

---

## SMSParser Tests

```dart
group('SMSParserService', () {

  test('identifies HDFC debit SMS', () {
    const sms = 'Rs.2500.00 debited from A/c ...1234 on 01-05-26. UPI:Swiggy.';
    final result = SMSParserService.parseSMS(senderAddress: 'HDFCBK', body: sms, date: DateTime.now());
    expect(result?.amount, 2500.0);
    expect(result?.type, TransactionType.expense);
    expect(result?.merchant, contains('Swiggy'));
  });

  test('identifies SBI credit SMS', () {
    const sms = 'Your A/c ...5678 credited by Rs 85,000.00 on 01-05-26 by NEFT.';
    final result = SMSParserService.parseSMS(senderAddress: 'SBIINB', body: sms, date: DateTime.now());
    expect(result?.amount, 85000.0);
    expect(result?.type, TransactionType.income);
  });

  test('ignores non-bank SMS', () {
    const sms = 'Your OTP is 123456. Valid for 5 minutes.';
    final result = SMSParserService.parseSMS(senderAddress: 'HDFCBK', body: sms, date: DateTime.now());
    expect(result, isNull);
  });

  test('handles Indian number format with commas', () {
    const sms = 'Rs.1,00,000.00 credited to your account.';
    final result = SMSParserService.parseSMS(senderAddress: 'SBIINB', body: sms, date: DateTime.now());
    expect(result?.amount, 100000.0);
  });
});
```

---

## Repository Tests

### ExpenseRepository
```dart
group('ExpenseRepository', () {
  late Database db;
  late ExpenseRepository repo;

  setUp(() async {
    db = await TestDatabase.create();
    await db.insert('wallets', Fixtures.wallet().toMap());
    repo = ExpenseRepository(db: db);
  });

  test('createExpense inserts and getById returns it', () async {
    final expense = Fixtures.expense(walletId: 'wallet-1');
    await repo.createExpense(expense);
    final found = await repo.getExpenseById(expense.id);
    expect(found?.amount, expense.amount);
  });

  test('getExpensesForMonth returns only that month', () async {
    await repo.createExpense(Fixtures.expense(date: DateTime(2026, 4, 15)));
    await repo.createExpense(Fixtures.expense(date: DateTime(2026, 3, 10))); // different month
    final results = await repo.getExpensesForMonth(2026, 4);
    expect(results.length, 1);
  });

  test('deleteExpense removes from DB', () async {
    final e = Fixtures.expense();
    await repo.createExpense(e);
    await repo.deleteExpense(e.id);
    expect(await repo.getExpenseById(e.id), isNull);
  });

  test('getTotalExpenseForPeriod sums correctly', () async {
    await repo.createExpense(Fixtures.expense(amount: 100));
    await repo.createExpense(Fixtures.expense(amount: 250));
    final total = await repo.getTotalExpenseForPeriod(
      DateTime(2026, 1, 1), DateTime(2026, 12, 31)
    );
    expect(total, 350.0);
  });
});
```

### WalletRepository
```dart
group('WalletRepository', () {
  test('getWalletBalance = openingBalance + income - expenses', () async {
    // Insert wallet with opening balance 1000
    // Insert expense 200, income 500
    // Expected balance = 1000 + 500 - 200 = 1300
    ...
    expect(balance, 1300.0);
  });

  test('archiveWallet changes status to archived', () async { ... });
  test('getActiveWallets excludes archived', () async { ... });
});
```

---

## EncryptionService Tests

```dart
group('EncryptionService', () {
  const key = 'test-key-32-chars-padding-needed!';

  test('encrypt then decrypt returns original content', () async {
    final original = File('${Directory.systemTemp.path}/test.txt')
      ..writeAsStringSync('Hello PocketLedger');
    final encrypted = await EncryptionService.encryptFile(original, key);
    final decrypted = await EncryptionService.decryptFile(encrypted, key);
    expect(decrypted.readAsStringSync(), 'Hello PocketLedger');
  });

  test('wrong key fails decryption', () async {
    final original = File('...')..writeAsStringSync('secret');
    final encrypted = await EncryptionService.encryptFile(original, key);
    expect(
      () => EncryptionService.decryptFile(encrypted, 'wrong-key'),
      throwsA(isA<DecryptionException>()),
    );
  });

  test('encrypted file is not readable as plaintext', () async {
    final original = File('...')..writeAsStringSync('secret data');
    final encrypted = await EncryptionService.encryptFile(original, key);
    expect(encrypted.readAsStringSync(), isNot(contains('secret data')));
  });
});
```

---

## InsightEngine Tests

```dart
group('InsightEngine', () {
  test('spending_spike fires when current month > last month by 30%', () async {
    final ctx = InsightContext(
      last3MonthsExpenses: [
        // April: Food = 1300 (spike vs March 1000)
        ...buildMonthExpenses(month: 4, category: 'food', total: 1300),
        ...buildMonthExpenses(month: 3, category: 'food', total: 1000),
      ],
      ...
    );
    final insights = await InsightEngine.run(ctx);
    expect(insights.any((i) => i.type == InsightType.spendingSpike), isTrue);
  });

  test('no spike when increase < 30%', () async {
    // April = 1250, March = 1000 → 25% increase, below threshold
    ...
    expect(insights.any((i) => i.type == InsightType.spendingSpike), isFalse);
  });

  test('budget_risk fires when burn rate exceeds pace', () async { ... });
  test('idle_wallet fires for wallet with no activity in 30 days', () async { ... });
  test('expired insights not included in results', () async { ... });
});
```
