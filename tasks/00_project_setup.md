# Task 00 — Project Setup

## Goal
Initialize the Flutter project with all required packages, folder structure, and CI configuration.

---

## Tasks

### Flutter Project Init
- [ ] Run `flutter create pocket_ledger --org com.pocketledger --platforms android,ios`
- [ ] Set minimum SDK: Android API 21, iOS 13
- [ ] Configure app name and bundle ID in `pubspec.yaml`, `AndroidManifest.xml`, `Info.plist`
- [ ] Set app icons (Android adaptive + iOS) using `flutter_launcher_icons`
- [ ] Set splash screen using `flutter_native_splash`

### Dependency Setup (`pubspec.yaml`)
- [ ] `sqflite` — SQLite ORM
- [ ] `path_provider` — File paths
- [ ] `riverpod` / `flutter_riverpod` — State management
- [ ] `go_router` — Navigation
- [ ] `google_sign_in` — Google OAuth
- [ ] `googleapis` — Google Drive API
- [ ] `flutter_local_notifications` — Local reminders
- [ ] `local_auth` — Fingerprint / Face ID
- [ ] `encrypt` — AES encryption for backup
- [ ] `archive` — ZIP for backup
- [ ] `intl` — Formatting (dates, currency, i18n)
- [ ] `fl_chart` — Charts and analytics
- [ ] `image_picker` — Receipt images
- [ ] `share_plus` — Export sharing
- [ ] `pdf` — PDF generation
- [ ] `excel` — Excel export
- [ ] `csv` — CSV export
- [ ] `permission_handler` — Runtime permissions
- [ ] `uuid` — Unique IDs for records
- [ ] `crypto` — PIN hashing (SHA-256)
- [ ] `flutter_secure_storage` — Secure key storage

### Folder Structure
- [ ] Create `lib/` structure:
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
- [ ] Create `DatabaseHelper` singleton (`core/database/database_helper.dart`)
- [ ] Define `onCreate` with all table creation SQL
- [ ] Define `onUpgrade` with migration logic
- [ ] Implement `onConfigure` to enable WAL mode and foreign keys (`PRAGMA foreign_keys = ON`)
- [ ] Write base repository abstract class

### Database Tables — Create All
- [ ] `security_settings`
- [ ] `user_profile`
- [ ] `wallets`
- [ ] `folders`
- [ ] `expenses`
- [ ] `income`
- [ ] `loans`
- [ ] `loan_payments`
- [ ] `contacts`
- [ ] `groups`
- [ ] `group_members`
- [ ] `group_transactions`
- [ ] `budgets`
- [ ] `attachments`
- [ ] `tags`
- [ ] `expense_tags`
- [ ] `backup_metadata`

### Indexes
- [ ] Index on `expenses(date)`, `expenses(folder_id)`, `expenses(wallet_id)`
- [ ] Index on `income(date)`
- [ ] Index on `loans(contact_id)`, `loans(due_date)`
- [ ] Index on `contacts(name)`

### Theme Setup
- [ ] Define light theme (`ThemeData`)
- [ ] Define dark theme (`ThemeData`)
- [ ] Create `AppColors`, `AppTextStyles`, `AppDimensions` constants
- [ ] Theme switching via Riverpod `StateNotifierProvider`

### Routing
- [ ] Configure `GoRouter` with routes for all screens
- [ ] Implement redirect guard: if no PIN set → onboarding, else → PIN lock screen

### CI / Quality
- [ ] Add `analysis_options.yaml` with strict lint rules
- [ ] Configure `flutter test` baseline
- [ ] Add `.gitignore` (Flutter preset + secrets)
- [ ] Add `README.md` to project root

---

## Acceptance Criteria
- `flutter run` launches with a blank scaffold on Android and iOS simulators
- All packages resolve without conflicts (`flutter pub get`)
- Database initializes and all tables exist on first launch
- No lint errors (`flutter analyze`)
