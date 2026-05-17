import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end: create loan → add payment → settle
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Loan flow', () {
    testWidgets('create loan, add payment, mark settled', (tester) async {
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Loans (via More menu or Settings drawer)
      final moreBtn = find.byTooltip('More');
      if (moreBtn.evaluate().isNotEmpty) {
        await tester.tap(moreBtn);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.textContaining('Loans'));
      await tester.pumpAndSettle();

      // Add a new loan
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill contact name manually
      await tester.enterText(find.byKey(const Key('contact_name')), 'Raj Kumar');

      // Select "Loan Given"
      await tester.tap(find.textContaining('Given'));
      await tester.pumpAndSettle();

      // Enter principal
      await tester.enterText(find.byKey(const Key('principal_field')), '5000');

      // Interest rate = 10%, simple
      await tester.enterText(find.byKey(const Key('interest_rate_field')), '10');
      await tester.tap(find.textContaining('Simple'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      // Verify loan appears
      expect(find.textContaining('Raj Kumar'), findsOneWidget);
      expect(find.textContaining('5,000'), findsOneWidget);

      // Tap to view detail
      await tester.tap(find.textContaining('Raj Kumar'));
      await tester.pumpAndSettle();

      // Add a payment
      await tester.tap(find.textContaining('Add Payment'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '2000');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify payment recorded
      expect(find.textContaining('2,000'), findsOneWidget);

      // Settle the loan
      await tester.tap(find.textContaining('Mark as Settled'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Settled'), findsOneWidget);
    });
  });
}
