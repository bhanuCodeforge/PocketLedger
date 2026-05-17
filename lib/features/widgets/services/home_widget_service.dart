import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Service that manages the PocketLedger home-screen widget data.
///
/// Call [initializeWidget] once at app startup (inside [main] or after the
/// first frame) and [updateWidgetData] whenever financial totals change.
class HomeWidgetService {
  // ── Constants ─────────────────────────────────────────────────────────────

  /// App-group identifier shared between the Flutter app and the widget
  /// extension on iOS.  Must match the value configured in Xcode.
  static const _appGroupId = 'group.com.pocketledger.widget';

  /// Android widget provider class name (registered in AndroidManifest.xml).
  static const _androidWidgetName = 'PocketLedgerWidget';

  /// Fully-qualified Android class name used when [updateWidget] requires it.
  static const _qualifiedAndroidName =
      'com.pocketledger.app.PocketLedgerWidget';

  /// iOS widget extension name as declared in the Widget Extension target.
  static const _iosWidgetName = 'PocketLedgerWidget';

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Must be called once before [updateWidgetData].  Sets the iOS app-group
  /// so that data is visible to the widget extension.
  static Future<void> initializeWidget() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      // Non-fatal – widgets simply won't update on iOS if app-group is missing.
      debugPrint('[HomeWidgetService] initializeWidget error: $e');
    }
  }

  // ── Data update ───────────────────────────────────────────────────────────

  /// Persists the latest financial snapshot and triggers a widget refresh.
  ///
  /// Values are stored under well-known keys read by both the Android
  /// AppWidgetProvider and the iOS WidgetKit timeline entry.
  static Future<void> updateWidgetData({
    required double todayExpense,
    required double monthExpense,
    required double totalBalance,
    required double todayIncome,
  }) async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<double>('today_expense', todayExpense),
        HomeWidget.saveWidgetData<double>('month_expense', monthExpense),
        HomeWidget.saveWidgetData<double>('total_balance', totalBalance),
        HomeWidget.saveWidgetData<double>('today_income', todayIncome),
        // Pre-formatted strings so the widget doesn't need to format on its own.
        HomeWidget.saveWidgetData<String>(
            'today_expense_fmt', _formatAmount(todayExpense)),
        HomeWidget.saveWidgetData<String>(
            'month_expense_fmt', _formatAmount(monthExpense)),
        HomeWidget.saveWidgetData<String>(
            'total_balance_fmt', _formatAmount(totalBalance)),
        HomeWidget.saveWidgetData<String>(
            'today_income_fmt', _formatAmount(todayIncome)),
        HomeWidget.saveWidgetData<String>(
            'last_updated', DateTime.now().toIso8601String()),
      ]);

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iosWidgetName,
        qualifiedAndroidName: _qualifiedAndroidName,
      );
    } catch (e) {
      debugPrint('[HomeWidgetService] updateWidgetData error: $e');
    }
  }

  // ── Widget interaction callback ───────────────────────────────────────────

  /// Registers a callback invoked when the user taps an interactive element
  /// inside the widget (e.g. a quick-add button).
  ///
  /// [callback] receives the URI that the widget sent (e.g. `pocketledger://add_expense`).
  static void registerInteractiveCallback(
      void Function(Uri? uri) callback) {
    HomeWidget.widgetClicked.listen(callback);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _formatAmount(double amount) {
    // Format with Indian comma grouping: 1,23,456.78
    final isNegative = amount < 0;
    final abs = amount.abs();
    final intPart = abs.truncate();
    final decPart = ((abs - intPart) * 100).round().toString().padLeft(2, '0');
    final formatted = _indianFormat(intPart);
    return '${isNegative ? '-' : ''}₹$formatted.$decPart';
  }

  static String _indianFormat(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    final lastThree = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    if (rest.isEmpty) return lastThree;
    // Group remaining digits in pairs.
    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i != 0 && (rest.length - i) % 2 == 0) buffer.write(',');
      buffer.write(rest[i]);
    }
    return '$buffer,$lastThree';
  }
}
