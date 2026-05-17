# PocketLedger

> Privacy-first, offline personal finance manager built with Flutter + SQLite.  
> No accounts. No cloud dependency. Your data stays on your device.

---

## Feature Overview

| Category | Features |
|----------|----------|
| **Tracking** | Expenses, Income, Wallets, Folders |
| **Loans** | Given/Taken, Simple & Compound interest, Payment history |
| **Groups** | Split bills equally, custom, or by %, Settle Up |
| **Budgets** | Category/wallet budgets, threshold alerts (50/80/100%) |
| **Reports** | Pie charts, bar charts, income vs expense trends |
| **Search** | Global full-text search across all transactions |
| **Security** | 6-digit PIN, Biometrics (fingerprint/Face ID), Auto-lock |
| **Backup** | AES-256 encrypted local backup + Google Drive |
| **Export** | PDF, CSV, Excel |
| **AI Insights** | Rule-based spending analysis, budget risk alerts |
| **OCR** | Receipt scanning with auto-fill (on-device ML Kit) |
| **SMS Import** | Bank SMS parsing for auto-categorization |
| **Widgets** | Android/iOS home screen widgets |
| **i18n** | English, Hindi, Arabic (RTL) |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **UI** | Flutter 3.32, Material 3 |
| **State** | Riverpod 2 (`Provider`, `FutureProvider`, `NotifierProvider`) |
| **Navigation** | go_router 13 (ShellRoute + nested routes) |
| **Database** | SQLite via sqflite — 23 tables, WAL mode |
| **Security** | local_auth, flutter_secure_storage, encrypt (AES-256) |
| **Backup** | archive (ZIP) + encrypt + Google Drive API |
| **Charts** | fl_chart |
| **OCR** | google_mlkit_text_recognition |
| **Notifications** | flutter_local_notifications |
| **i18n** | flutter_localizations + intl ARB |

---

## Quick Start

### Prerequisites
- Flutter SDK ≥ 3.19 (Dart ≥ 3.3)
- Android SDK API 21+ **or** Xcode 15+
- VSCode with [Dart + Flutter extensions](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)

### Setup

```bash
# 1. Clone
git clone <repo-url>
cd pocket_ledger

# 2. Install dependencies
flutter pub get

# 3. Generate localization files
flutter gen-l10n

# 4. Generate app icons + splash (optional, assets already committed)
dart run flutter_launcher_icons
dart run flutter_native_splash:create

# 5. Run
flutter run
```

> **Tip:** Use the VSCode task `flutter: full setup` (Ctrl+Shift+P → Run Task) to execute steps 2–4 in one shot.

### Build for Distribution

```bash
# Android APK (sideload)
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## Project Structure

```
lib/
├── main.dart                        # Entry point (ProviderScope + orientation lock)
├── app.dart                         # MaterialApp.router (theme, locale, router)
├── core/
│   ├── constants/app_constants.dart # App-wide constants (PIN length, currencies, etc.)
│   ├── database/
│   │   ├── database_helper.dart     # SQLite singleton, DDL for 23 tables
│   │   └── base_repository.dart    # Abstract base: Future<Database> get db
│   ├── navigation/app_router.dart  # GoRouter config + redirect guards
│   ├── providers/
│   │   ├── app_init_provider.dart   # FutureProvider: DB init + profile load
│   │   └── auth_state_provider.dart # bool: authenticated past PIN screen
│   ├── theme/
│   │   ├── app_colors.dart          # All brand + semantic + category colors
│   │   ├── app_text_styles.dart     # Typography scale
│   │   └── app_theme.dart          # Light + Dark ThemeData
│   └── utils/currency_formatter.dart
│
├── features/
│   ├── auth/
│   │   ├── data/security_repository.dart  # PIN hash, biometric, lockout
│   │   └── presentation/pin_lock_screen.dart
│   ├── onboarding/presentation/onboarding_screen.dart  # 5-step first-run flow
│   ├── splash/presentation/splash_screen.dart
│   ├── dashboard/
│   │   ├── presentation/dashboard_shell.dart  # BottomNavigationBar shell
│   │   └── presentation/dashboard_screen.dart # Home: balances, recent txns
│   ├── expenses/
│   │   ├── data/expense.dart                  # Model + ExpenseCategory/PaymentMode enums
│   │   ├── data/expense_repository.dart       # CRUD + aggregates
│   │   ├── data/expense_providers.dart        # Riverpod providers
│   │   └── presentation/                      # expenses_screen, add, detail
│   ├── income/                                # Mirrors expenses structure
│   ├── wallets/                               # Wallet CRUD + balance calc
│   ├── folders/                               # Nested folder tree
│   ├── loans/                                 # SI/CI loans + payment tracking
│   ├── contacts/                              # Contact book
│   ├── groups/                                # Split bills, settle up
│   ├── budgets/                               # Budgets with spend tracking
│   ├── reports/presentation/reports_screen.dart   # Charts + export
│   ├── search/presentation/search_screen.dart     # Global search + debounce
│   ├── insights/
│   │   ├── data/                              # AiInsight model + repository
│   │   ├── services/insights_engine.dart      # Rule-based analysis engine
│   │   └── presentation/insights_screen.dart
│   ├── ocr/
│   │   ├── services/ocr_service.dart          # MLKit text recognition
│   │   └── presentation/ocr_screen.dart
│   ├── sms/services/sms_service.dart          # Bank SMS parser
│   ├── export/services/export_service.dart    # PDF, CSV, Excel
│   ├── backup/services/backup_service.dart    # AES-ZIP local backup
│   ├── notifications/services/notification_service.dart
│   ├── sync/services/sync_service.dart        # change_log writer
│   ├── widgets/services/home_widget_service.dart  # Home screen widget bridge
│   └── settings/
│       ├── data/user_profile_repository.dart
│       └── presentation/                      # All settings screens
│
├── l10n/
│   ├── app_en.arb   # English (default)
│   ├── app_hi.arb   # Hindi
│   └── app_ar.arb   # Arabic (RTL)
├── generated/l10n/  # Auto-generated (do not edit)
└── shared/
    ├── providers/
    │   ├── theme_provider.dart   # ThemeMode state
    │   ├── locale_provider.dart  # Locale state
    │   └── user_profile_provider.dart  # UserProfile + currencyProvider
    └── widgets/                  # Shared UI components
```

---

## Navigation Map

```
/splash         → SplashScreen          (runs init, redirects)
/onboarding     → OnboardingScreen      (5-page first-run flow)
/lock           → PinLockScreen         (PIN + biometric)

ShellRoute (DashboardShell — BottomNavigationBar)
├── /dashboard              → DashboardScreen
├── /expenses               → ExpensesScreen
│   ├── /expenses/add       → AddExpenseScreen (modal, rootNavigator)
│   ├── /expenses/:id       → ExpenseDetailScreen
│   └── /expenses/:id/edit  → AddExpenseScreen (edit mode)
├── /income
│   ├── /income/add
│   └── /income/:id/edit
├── /wallets
│   └── /wallets/add
├── /folders
│   └── /folders/add
├── /loans
│   ├── /loans/add
│   └── /loans/:id
├── /budgets
│   └── /budgets/add
├── /contacts
│   └── /contacts/add
├── /groups
│   ├── /groups/add
│   └── /groups/:id
├── /reports
├── /search
├── /insights
├── /ocr                    (rootNavigator — full-screen camera)
└── /settings
    ├── /settings/profile
    ├── /settings/theme
    ├── /settings/language
    ├── /settings/security
    └── /settings/backup
```

**Redirect guards** (in `routerProvider`):
1. App still loading → `/splash`
2. Onboarding not complete → `/onboarding`
3. Has PIN, not authenticated → `/lock`
4. Authenticated + going to `/lock` → `/dashboard`

---

## Database Schema (key tables)

| Table | Key columns |
|-------|-------------|
| `user_profile` | name, currency_code, language_code, theme_mode |
| `security_settings` | pin_hash, biometric_enabled, auto_lock_minutes |
| `wallets` | name, type, opening_balance, is_archived |
| `folders` | name, parent_id, color, icon, status |
| `expenses` | wallet_id, folder_id, amount, category, payment_mode, expense_date |
| `income` | wallet_id, folder_id, amount, source, income_date |
| `loans` | contact_id, type(given/taken), principal_amount, interest_type |
| `loan_payments` | loan_id, amount, payment_date |
| `contacts` | name, phone, email |
| `groups` + `group_members` + `group_transactions` + `group_transaction_splits` | — |
| `budgets` | category, amount, period, alert_at_percent |
| `tags` + `entity_tags` | tag-to-expense/income many-to-many |
| `attachments` | entity_id, entity_type, file_path |
| `ai_insights` | insight_type, title, body, expires_at |
| `change_log` | entity_type, operation, synced |
| `backup_metadata` | file_name, checksum, drive_file_id |

> **Timestamps**: All `created_at` / `updated_at` / date fields use **milliseconds since epoch** (int), not ISO strings.

---

## Security Model

- PIN: 6-digit, hashed with **SHA-256 + per-device salt** (stored in `flutter_secure_storage`)
- Biometric: delegated to OS via `local_auth`; falls back to PIN
- Auto-lock: configurable 1/5/15/30 min; tracked via `AppLifecycleObserver`
- Backup encryption: **AES-256 CBC**, key derived from PIN hash; IV stored alongside cipher
- No data leaves the device unless user explicitly triggers a Google Drive backup

---

## Localization

Add a new language:
1. Create `lib/l10n/app_XX.arb` (copy from `app_en.arb`, translate values)
2. Add `Locale('XX')` to `supportedLocales` in `lib/shared/providers/locale_provider.dart`
3. Add the language card in `lib/features/settings/presentation/language_settings_screen.dart`
4. Run `flutter gen-l10n`

---

## Testing

```bash
# Unit + widget tests
flutter test

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integration tests (requires connected device/emulator)
flutter test integration_test/onboarding_flow_test.dart
flutter test integration_test/expense_flow_test.dart
flutter test integration_test/loan_flow_test.dart
flutter test integration_test/backup_flow_test.dart
```

---

## License

MIT — see [LICENSE](LICENSE)
