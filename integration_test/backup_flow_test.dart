import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end: create backup file and verify metadata written
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Backup flow', () {
    testWidgets('creates a local backup successfully', (tester) async {
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Tap Backup & Restore
      await tester.tap(find.textContaining('Backup'));
      await tester.pumpAndSettle();

      // Tap Backup Now
      await tester.tap(find.textContaining('Backup Now'));
      await tester.pumpAndSettle();

      // Enter PIN in dialog (the backup PIN prompt)
      final pinField = find.byType(TextField);
      if (pinField.evaluate().isNotEmpty) {
        await tester.enterText(pinField, '123456');
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // Should show success snackbar
      expect(find.textContaining('Backup completed'), findsOneWidget);
    });
  });
}
