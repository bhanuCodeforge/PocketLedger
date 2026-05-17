import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_ledger/main.dart' as app;

/// End-to-end test: first launch → onboarding → PIN setup → dashboard
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding flow', () {
    testWidgets('completes onboarding and lands on dashboard', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should see splash then redirect to onboarding (first launch)
      expect(find.textContaining('Welcome'), findsOneWidget);

      // Tap "Get Started" or "Next"
      final nextBtn = find.widgetWithText(ElevatedButton, 'Get Started');
      if (nextBtn.evaluate().isNotEmpty) {
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
      }

      // Currency selection screen
      expect(find.textContaining('Currency'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Wallet creation screen
      expect(find.textContaining('Wallet'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'My Wallet');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // PIN setup screen — enter 6 digits
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('$i'));
        await tester.pumpAndSettle();
      }

      // PIN confirm — same 6 digits
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('$i'));
        await tester.pumpAndSettle();
      }

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should land on Dashboard
      expect(find.textContaining('Total Balance'), findsOneWidget);
    });
  });
}
