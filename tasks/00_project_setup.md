# Task 00 — Project Setup

## Goal
Initialize the Flutter project with all required packages, folder structure, and CI configuration.

---

## Tasks

### Flutter Project Init
- [x] Run `flutter create pocket_ledger --org com.pocketledger --platforms android,ios`
- [x] Set minimum SDK: Android API 21, iOS 13
- [x] Configure app name and bundle ID in `pubspec.yaml`, `AndroidManifest.xml`, `Info.plist`
- [x] Set app icons (Android adaptive + iOS) using `flutter_launcher_icons`
- [x] Set splash screen using `flutter_native_splash`

### Dependency Setup (`pubspec.yaml`)
- [x] `sqflite` — SQLite ORM
- [x] `path_provider` — File paths
- [x] `riverpod` / `flutter_riverpod` — State management
- [x] `go_router` — Navigation
- [x] `google_sign_in` — Google OAuth
- [x] `googleapis` — Google Drive API
- [x] `flutter_local_notifications` — Local reminders
- [x] `local_auth` — Fingerprint / Face ID
- [x] `encrypt` — AES encryption for backup
- [x] `archive` — ZIP for backup
- [x] `intl` — Formatting (dates, currency, i18n)
- [x] `fl_chart` — Charts and analytics
- [x] `image_picker` — Receipt images
- [x] `share_plus` — Export sharing
- [x] `pdf` — PDF generation
- [x] `excel` — Excel export
- [x] `csv` — CSV export
- [x] `permission_handler` — Runtime permissions
- [x] `uuid` — Unique IDs for records
- [x] `crypto` — PIN hashing (SHA-256)
- [x] `flutter_secure_storage` — Secure key storage

### Folder Structure
- [x] Create `lib/` structure:
  ```
  lib/
  ├── main.dart
  ├── app.dart
  ├── core/
  │   ├── database/
  │   ├── constants/
  │   ├── utils/
  │   └── theme/
  ├── features/
  │   ├── auth/
  │   ├── dashboard/
  │   ├── wallet/
  │   ├── folder/
  │   ├── expense/
  │   ├── income/
  │   ├── loan/
  │   ├── contact/
  │   ├── group/
  │   ├── budget/
  │   ├── report/
  │   ├── search/
  │   ├── backup/
  │   ├── export/
  │   └── settings/
  └── shared/
      ├── widgets/
      ├── models/
      └── providers/
  ```

### Database Layer
- [x] Create `DatabaseHelper` singleton (`core/database/database_helper.dart`)
- [x] Define `onCreate` with all table creation SQL
- [x] Define `onUpgrade` with migration logic
- [x] Implement `onConfigure` to enable WAL mode and foreign keys (`PRAGMA foreign_keys = ON`)
- [x] Write base repository abstract class

### Database Tables — Create All
- [x] `security_settings`
- [x] `user_profile`
- [x] `wallets`
- [x] `folders`
- [x] `expenses`
- [x] `income`
- [x] `loans`
- [x] `loan_payments`
- [x] `contacts`
- [x] `groups`
- [x] `group_members`
- [x] `group_transactions`
- [x] `budgets`
- [x] `attachments`
- [x] `tags`
- [x] `expense_tags`
- [x] `backup_metadata`

### Indexes
- [x] Index on `expenses(date)`, `expenses(folder_id)`, `expenses(wallet_id)`
- [x] Index on `income(date)`
- [x] Index on `loans(contact_id)`, `loans(due_date)`
- [x] Index on `contacts(name)`

### Theme Setup
- [x] Define light theme (`ThemeData`)
- [x] Define dark theme (`ThemeData`)
- [x] Create `AppColors`, `AppTextStyles`, `AppDimensions` constants
- [x] Theme switching via Riverpod `StateNotifierProvider`

### Routing
- [x] Configure `GoRouter` with routes for all screens
- [x] Implement redirect guard: if no PIN set → onboarding, else → PIN lock screen

### CI / Quality
- [x] Add `analysis_options.yaml` with strict lint rules
- [x] Configure `flutter test` baseline
- [x] Add `.gitignore` (Flutter preset + secrets)
- [x] Add `README.md` to project root

---

## Acceptance Criteria
- `flutter run` launches with a blank scaffold on Android and iOS simulators
- All packages resolve without conflicts (`flutter pub get`)
- Database initializes and all tables exist on first launch
- No lint errors (`flutter analyze`)
