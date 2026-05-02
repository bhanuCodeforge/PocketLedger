# PocketLedger — Task Index

Personal offline-first finance app built with Flutter + SQLite + Google Drive backup.

## Stack
- **Mobile:** Flutter (Android & iOS)
- **Database:** SQLite (`sqflite`)
- **Cloud Backup:** Google Drive API (`googleapis`, `google_sign_in`)
- **Notifications:** `flutter_local_notifications`
- **Auth:** `local_auth`
- **State:** Riverpod
- **Navigation:** GoRouter
- **Charts:** fl_chart

---

## Architecture Docs

| File | Scope |
|------|-------|
| [architecture/db_schema](./architecture/db_schema.md) | Full DDL, all 23 tables, indexes, ERD, migrations |
| [architecture/state_management](./architecture/state_management.md) | Riverpod patterns, provider map, invalidation strategy |
| [architecture/navigation_map](./architecture/navigation_map.md) | GoRouter tree, guards, transitions, deep links |

---

## Module Tasks (v1.0)

| File | Scope |
|------|-------|
| [00_project_setup](./00_project_setup.md) | Flutter project init, dependencies, CI |
| [01_app_initialization](./01_app_initialization.md) | Splash, onboarding, permissions, theme |
| [02_authentication_security](./02_authentication_security.md) | PIN, biometrics, recovery phrase, edge cases |
| [03_user_profile](./03_user_profile.md) | Name, currency, language, timezone |
| [04_wallet_management](./04_wallet_management.md) | Wallets CRUD, balance tracking, edge cases |
| [05_folder_management](./05_folder_management.md) | Nested folders, icons, colors |
| [06_expense_management](./06_expense_management.md) | Expense CRUD, tags, attachments, edge cases |
| [07_income_management](./07_income_management.md) | Income tracking |
| [12_dashboard](./12_dashboard.md) | Widgets, summary cards, shimmer, FAB |
| [17_backup_system](./17_backup_system.md) | Google Drive backup/restore, encryption, edge cases |
| [19_settings](./19_settings.md) | Theme, language, export prefs, danger zone |
| [20_export](./20_export.md) | PDF, CSV, Excel export |

## Module Tasks (v1.5)

| File | Scope |
|------|-------|
| [08_loan_management](./08_loan_management.md) | Loans, SI/CI formulas, payments, edge cases |
| [09_contact_ledger](./09_contact_ledger.md) | Contacts, balances, history |
| [11_budget_management](./11_budget_management.md) | Budgets, threshold alerts |
| [15_notifications](./15_notifications.md) | Local reminders, due alerts |
| [18_sync_engine](./18_sync_engine.md) | Change triggers, incremental backup, conflict resolution |

## Module Tasks (v2.0)

| File | Scope |
|------|-------|
| [10_group_split](./10_group_split.md) | Groups, equal/custom/% splits, settlements |
| [13_reports_analytics](./13_reports_analytics.md) | Charts, daily/weekly/monthly/yearly |
| [14_search](./14_search.md) | Global search, debounce, filters |
| [16_file_attachments](./16_file_attachments.md) | Receipt images, PDF viewer, orphan cleanup |
| [24_home_screen_widgets](./24_home_screen_widgets.md) | Android & iOS home screen widgets |

## Module Tasks (v3.0)

| File | Scope |
|------|-------|
| [21_ocr_receipt_scan](./21_ocr_receipt_scan.md) | On-device ML receipt scanning, auto-fill |
| [22_sms_import](./22_sms_import.md) | Bank SMS parsing, duplicate detection |
| [23_ai_insights](./23_ai_insights.md) | On-device rule-based insights engine |

---

## Testing

| File | Scope |
|------|-------|
| [testing/test_strategy](./testing/test_strategy.md) | Philosophy, tooling, CI, coverage targets |
| [testing/unit_tests](./testing/unit_tests.md) | Full test cases: calculators, parsers, repos, services |
| [testing/widget_integration_tests](./testing/widget_integration_tests.md) | Widget tests + 6 integration flows |

---

## Release Plan

| File | Scope |
|------|-------|
| [release_plan](./release_plan.md) | v1.0 → v3.0 milestones, checklists, constraints |

---

## Status Legend
- `[ ]` Not started
- `[~]` In progress
- `[x]` Done
