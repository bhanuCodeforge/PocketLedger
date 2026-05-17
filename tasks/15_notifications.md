# Task 15 — Notifications (Module 15)

## Goal
Schedule local reminders for loan due dates, EMIs, bills, and budget warnings. Fully offline.

---

## Tasks

### Package Setup
- [x] Add `flutter_local_notifications` to `pubspec.yaml`
- [x] Android: create notification channel (`pocket_ledger_channel`) in `AndroidManifest.xml`
- [x] iOS: request notification permission during onboarding

### Notification Service
- [x] `NotificationService` singleton:
  - [x] `initialize()` — set up plugin, request permissions
  - [x] `scheduleNotification({id, title, body, scheduledDate})` — exact alarm
  - [x] `cancelNotification(int id)`
  - [x] `cancelAll()`
  - [x] `showImmediate({title, body})` — for budget alerts

### Notification ID Strategy
- [x] Loan due reminders: ID prefix `1000 + loan index`
- [x] Budget alerts: ID prefix `2000 + budget index`
- [x] Bill reminders: ID prefix `3000 + bill index`
- [x] Avoid ID collisions by using deterministic hash of entity UUID

### Loan Due Reminders
- [x] On loan creation or due_date change, schedule notifications:
  - [x] 7 days before due date: "Loan reminder: ₹X due in 7 days from [Contact]"
  - [x] 3 days before: "Loan due in 3 days"
  - [x] Day of: "Loan payment due today"
- [x] Cancel existing reminders when loan is settled or deleted

### Budget Alerts
- [x] After every expense save, check all budgets (Module 11 logic)
- [x] If threshold crossed:
  - [x] Show immediate local notification: "[Budget] has reached 80%"
  - [x] Store last alerted % in `budgets.last_alert_sent` (add column or in-memory)

### Bill / Recurring Reminders (v1.5)
- [x] Mark any expense as recurring (daily/weekly/monthly)
- [x] Schedule next-occurrence reminder 1 day before
- [x] Auto-advance recurring date when marked paid

### Settings for Notifications
- [x] Notification settings screen under Settings:
  - [x] Enable/Disable all notifications toggle
  - [x] Loan reminders toggle + lead time (1/3/7 days)
  - [x] Budget alerts toggle
  - [x] Quiet hours: start time, end time (suppress during quiet hours)

### On App Launch
- [x] Re-schedule all pending notifications (they may have been cancelled by OS)
- [x] Run `rescheduleAll()` in `appInitProvider`

### Providers
- [x] `notificationSettingsProvider` — `StateNotifierProvider`

---

## Acceptance Criteria
- Notifications fire at correct time on Android and iOS
- Cancelling a loan cancels its notifications
- Quiet hours suppress notifications correctly
- Budget alert shows immediately after expense pushes budget over threshold
