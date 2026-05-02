# Task 15 — Notifications (Module 15)

## Goal
Schedule local reminders for loan due dates, EMIs, bills, and budget warnings. Fully offline.

---

## Tasks

### Package Setup
- [ ] Add `flutter_local_notifications` to `pubspec.yaml`
- [ ] Android: create notification channel (`pocket_ledger_channel`) in `AndroidManifest.xml`
- [ ] iOS: request notification permission during onboarding

### Notification Service
- [ ] `NotificationService` singleton:
  - [ ] `initialize()` — set up plugin, request permissions
  - [ ] `scheduleNotification({id, title, body, scheduledDate})` — exact alarm
  - [ ] `cancelNotification(int id)`
  - [ ] `cancelAll()`
  - [ ] `showImmediate({title, body})` — for budget alerts

### Notification ID Strategy
- [ ] Loan due reminders: ID prefix `1000 + loan index`
- [ ] Budget alerts: ID prefix `2000 + budget index`
- [ ] Bill reminders: ID prefix `3000 + bill index`
- [ ] Avoid ID collisions by using deterministic hash of entity UUID

### Loan Due Reminders
- [ ] On loan creation or due_date change, schedule notifications:
  - [ ] 7 days before due date: "Loan reminder: ₹X due in 7 days from [Contact]"
  - [ ] 3 days before: "Loan due in 3 days"
  - [ ] Day of: "Loan payment due today"
- [ ] Cancel existing reminders when loan is settled or deleted

### Budget Alerts
- [ ] After every expense save, check all budgets (Module 11 logic)
- [ ] If threshold crossed:
  - [ ] Show immediate local notification: "[Budget] has reached 80%"
  - [ ] Store last alerted % in `budgets.last_alert_sent` (add column or in-memory)

### Bill / Recurring Reminders (v1.5)
- [ ] Mark any expense as recurring (daily/weekly/monthly)
- [ ] Schedule next-occurrence reminder 1 day before
- [ ] Auto-advance recurring date when marked paid

### Settings for Notifications
- [ ] Notification settings screen under Settings:
  - [ ] Enable/Disable all notifications toggle
  - [ ] Loan reminders toggle + lead time (1/3/7 days)
  - [ ] Budget alerts toggle
  - [ ] Quiet hours: start time, end time (suppress during quiet hours)

### On App Launch
- [ ] Re-schedule all pending notifications (they may have been cancelled by OS)
- [ ] Run `rescheduleAll()` in `appInitProvider`

### Providers
- [ ] `notificationSettingsProvider` — `StateNotifierProvider`

---

## Acceptance Criteria
- Notifications fire at correct time on Android and iOS
- Cancelling a loan cancels its notifications
- Quiet hours suppress notifications correctly
- Budget alert shows immediately after expense pushes budget over threshold
