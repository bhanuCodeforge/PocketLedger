import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Wrapper around [FlutterLocalNotificationsPlugin] that provides
/// high-level helpers for PocketLedger notifications.
///
/// Call [NotificationService.instance.initialize()] from `main()` before
/// [runApp].
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // ── Channel identifiers ───────────────────────────────────────────────────
  static const _channelIdReminders = 'pocket_ledger_reminders';
  static const _channelNameReminders = 'Payment Reminders';
  static const _channelDescReminders =
      'Reminders for upcoming loan and bill payments';

  static const _channelIdBudget = 'pocket_ledger_budget';
  static const _channelNameBudget = 'Budget Alerts';
  static const _channelDescBudget =
      'Alerts when spending approaches or exceeds budget limits';

  static const _channelIdGeneral = 'pocket_ledger_general';
  static const _channelNameGeneral = 'General';
  static const _channelDescGeneral = 'General PocketLedger notifications';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Initialization ────────────────────────────────────────────────────────

  /// Initializes the notification plugin and timezone database.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    // Create Android notification channels
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelIdReminders,
            _channelNameReminders,
            description: _channelDescReminders,
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ));

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelIdBudget,
            _channelNameBudget,
            description: _channelDescBudget,
            importance: Importance.defaultImportance,
            enableVibration: true,
            playSound: true,
          ));

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelIdGeneral,
            _channelNameGeneral,
            description: _channelDescGeneral,
            importance: Importance.defaultImportance,
          ));
    }

    _initialized = true;
  }

  // ── Permission ────────────────────────────────────────────────────────────

  /// Requests notification permission from the OS.
  ///
  /// On Android 13+ this triggers the POST_NOTIFICATIONS runtime permission.
  /// On iOS this shows the system permission dialog.
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (Platform.isIOS || Platform.isMacOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return true;
  }

  // ── Scheduled reminders ───────────────────────────────────────────────────

  /// Schedules a one-time notification at [scheduledDate].
  ///
  /// [id] must be unique per notification; reusing an id replaces the existing
  /// scheduled notification.
  Future<void> schedulePaymentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _ensureInitialized();

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _channelIdReminders,
      _channelNameReminders,
      channelDescription: _channelDescReminders,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Instant alerts ────────────────────────────────────────────────────────

  /// Shows an immediate budget alert notification.
  ///
  /// [category] is the budget category name.
  /// [percent] is the current spending percentage (e.g. 85 for 85%).
  Future<void> showBudgetAlert({
    required String category,
    required int percent,
  }) async {
    await _ensureInitialized();

    final id = category.hashCode.abs() % 100000;
    final title = 'Budget Alert: $category';
    final body = percent >= 100
        ? 'You have exceeded your $category budget!'
        : 'You have used $percent% of your $category budget.';

    const androidDetails = AndroidNotificationDetails(
      _channelIdBudget,
      _channelNameBudget,
      channelDescription: _channelDescBudget,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(id, title, body, details);
  }

  /// Shows a general-purpose notification immediately.
  Future<void> showGeneral({
    required int id,
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      _channelIdGeneral,
      _channelNameGeneral,
      channelDescription: _channelDescGeneral,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(id, title, body, details);
  }

  // ── Cancellation ─────────────────────────────────────────────────────────

  /// Cancels the notification with the given [id].
  Future<void> cancelNotification(int id) async {
    await _ensureInitialized();
    await _plugin.cancel(id);
  }

  /// Cancels all pending and displayed notifications.
  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }

  // ── Pending list ──────────────────────────────────────────────────────────

  /// Returns a list of all pending (scheduled but not yet shown) notifications.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await _ensureInitialized();
    return _plugin.pendingNotificationRequests();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }
}

// Top-level callback required by flutter_local_notifications for foreground
// tap handling.
@pragma('vm:entry-point')
void _onNotificationResponse(NotificationResponse response) {
  // Route to the relevant screen based on payload if needed.
  // Currently a no-op; integrate with GoRouter via a global key if required.
  debugPrint('[NotificationService] tapped: ${response.id} '
      'payload=${response.payload}');
}

// Top-level callback for background notification taps (Android).
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint('[NotificationService] background tap: ${response.id}');
}
