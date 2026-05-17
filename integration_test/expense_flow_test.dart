import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end: add expense → verify on list → edit → delete
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Expense CRUD flow', () {
    testWidgets('add, view, edit, and delete an expense', (tester) async {
      // Assumes onboarding already completed (use fresh DB per test run or
      // seed the DB with a profile + wallet before this test).
      // For a full E2E: run after onboarding_flow_test in the same session.

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Expenses tab
      final expensesTab = find.byIcon(Icons.receipt_long);
      if (expensesTab.evaluate().isNotEmpty) {
        await tester.tap(expensesTab);
        await tester.pumpAndSettle();
      }

      // Tap FAB to add expense
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter amount
      await tester.enterText(find.byKey(const Key('amount_field')), '250.00');
      await tester.pumpAndSettle();

      // Select category "Food"
      await tester.tap(find.textContaining('Food'));
      await tester.pumpAndSettle();

      // Enter note
      final noteField = find.byKey(const Key('note_field'));
      if (noteField.evaluate().isNotEmpty) {
        await tester.enterText(noteField, 'Lunch with team');
        await tester.pumpAndSettle();
      }

      // Save
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      // Verify expense appears in list
      expect(find.textContaining('250'), findsOneWidget);

      // Tap expense to view detail
      await tester.tap(find.textContaining('250'));
      await tester.pumpAndSettle();

      // Should see detail screen
      expect(find.textContaining('Food'), findsOneWidget);

      // Edit — tap edit icon
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Change amount
      final amountField = find.byKey(const Key('amount_field'));
      await tester.enterText(amountField, '300.00');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('300'), findsOneWidget);

      // Delete
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete')); // confirm dialog
      await tester.pumpAndSettle();

      // Back on list — expense gone
      expect(find.textContaining('300'), findsNothing);
    });
  });
}
