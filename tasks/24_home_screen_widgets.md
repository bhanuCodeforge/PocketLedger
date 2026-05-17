# Task 24 — Home Screen Widgets (Module 24 / v2.0+)

## Goal
Android home screen widgets and iOS Lock Screen / Home Screen widgets showing key financial data without opening the app.

---

## Tasks

### Package
- [x] Add `home_widget` to `pubspec.yaml`
- [x] Android: configure `AppWidgetProvider` in `AndroidManifest.xml`
- [x] iOS: create a Widget Extension target in Xcode (SwiftUI)

---

## Android Widgets

### Widget 1: Today Summary (2×1)
- Displays:
  - Today's expense total (red)
  - Today's income total (green)
  - Net for today
- Update trigger: on every expense/income add
- Tap: opens app → Dashboard

### Widget 2: Wallet Balance (2×1)
- Dropdown/config: user selects which wallet
- Displays:
  - Wallet name + type icon
  - Current balance
- Tap: opens app → Wallet detail

### Widget 3: Budget Status (2×2)
- Shows top 3 budgets with progress bars
- Color-coded: green/orange/red
- Tap: opens app → Budget list

### Widget 4: Monthly Overview (4×2)
- Bar chart of expenses for current month (day by day)
- Total expense and income this month
- Tap: opens app → Reports

---

## iOS Widgets

### Small Widget (2×2)
- Today's expense total
- App icon + "PocketLedger" label
- Tap: opens app Dashboard

### Medium Widget (4×2)
- Today expense + month expense + total balance
- Wallet name

### Lock Screen Widget (iOS 16+)
- Single number: today's expense total
- Updates hourly

---

## Data Sharing (Flutter ↔ Widget)

Use `home_widget` shared preferences bridge:
```dart
// After every write:
HomeWidget.saveWidgetData('today_expense', todayTotal);
HomeWidget.saveWidgetData('month_expense', monthTotal);
HomeWidget.saveWidgetData('wallet_balance_${walletId}', balance);
HomeWidget.updateWidget(name: 'PocketLedgerWidget');
```

Android native reads from `SharedPreferences` in `AppWidgetProvider.onUpdate()`.
iOS Swift reads from App Group `UserDefaults`.

### App Group Setup
- [x] iOS: create App Group `group.com.pocketledger.widget`
- [x] Register app + widget extension in same App Group in Xcode
- [x] Flutter side: configure `home_widget` with App Group ID

---

## Widget Configuration Screen
- [x] Long-press widget → "Configure" → opens in-app screen
- [x] Wallet selector for Wallet Balance widget
- [x] Budget count selector for Budget Status widget (1–5)
- [x] Save → triggers widget re-render

---

## Update Strategy
- [x] Update widget data after every expense/income write (in repository layer)
- [x] Limit widget updates to max 1 per minute (Android OS limits to ~100/day)
- [x] Fallback: widget shows "Open app to refresh" if data is stale > 6 hours

---

## Acceptance Criteria
- All Android widgets install from widget picker and show correct data
- iOS widgets show on Home Screen and Lock Screen (iOS 16+)
- Widget data updates within 30 seconds of a new transaction
- Tapping any widget opens the correct screen in the app
- No PIN bypass — widgets show data without requiring authentication (by design, data is not sensitive enough to hide)
