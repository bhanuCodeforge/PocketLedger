# Release Plan

## Version 1.0 — Foundation
**Target:** Core daily-use features. Fully offline. Stable.

### Included Modules
- [x] 00 — Project Setup
- [x] 01 — App Initialization (splash, onboarding, theme)
- [x] 02 — Authentication & Security (PIN, biometrics, recovery phrase)
- [x] 03 — User Profile (name, currency, language)
- [x] 04 — Wallet Management (CRUD, balance tracking)
- [x] 05 — Folder Management (nested, icons, colors)
- [x] 06 — Expense Management (full CRUD, tags, attachments)
- [x] 07 — Income Management
- [x] 12 — Dashboard (today, month, wallets, recent transactions)
- [x] 17 — Backup System (Google Drive manual backup + restore)
- [x] 19 — Settings (theme, PIN change, currency)
- [x] 20 — Export (PDF, CSV, Excel)

### Release Checklist
- [ ] All v1.0 modules complete and passing acceptance criteria
- [ ] Flutter analyze: 0 errors
- [ ] Manual test on Android (API 21, 28, 34)
- [ ] Manual test on iOS (iOS 13, 16, 17)
- [ ] DB migration script tested (fresh install + upgrade)
- [ ] Backup → Restore round-trip verified
- [ ] App size < 30 MB (APK), < 50 MB (IPA)
- [ ] Submit to Google Play (internal testing track)
- [ ] Submit to App Store (TestFlight)

---

## Version 1.5 — Relationships & Reminders
**Target:** Loans, contacts, budgets, and local notifications.

### Included Modules
- [ ] 08 — Loan Management (simple + compound interest, payments)
- [ ] 09 — Contact Ledger (history, outstanding balance)
- [ ] 11 — Budget Management (monthly, folder, category alerts)
- [ ] 15 — Notifications (loan due, budget alerts, reminders)
- [ ] 18 — Sync Engine (change log, incremental backup)

### New in 1.5
- Auto-backup on schedule (WorkManager / BGTask)
- Incremental backup (only changed records)
- Notification for overdue loans and budget thresholds

### Release Checklist
- [ ] All v1.5 modules complete
- [ ] Interest formula unit tests pass (100% coverage on `LoanCalculator`)
- [ ] Notification fires correctly on Android 13+ and iOS 16+
- [ ] Auto-backup tested on background wake
- [ ] Upgrade from v1.0 DB tested (migration adds new tables)

---

## Version 2.0 — Social & Insights
**Target:** Group splitting, full analytics, file attachments at scale.

### Included Modules
- [ ] 10 — Group Split (equal, custom, percentage; settlements)
- [ ] 13 — Reports & Analytics (charts, cash flow, category breakdown)
- [ ] 14 — Search (global full-text)
- [ ] 16 — File Attachments (receipt images, PDF viewer)

### New in 2.0
- `fl_chart` integration with interactive charts
- Global search with real-time results
- Attachment storage with orphan cleanup
- Full-screen image viewer with pinch-to-zoom

### Release Checklist
- [ ] Group split with all split types tested end-to-end
- [ ] Settlement algorithm produces minimal number of transfers
- [ ] Charts render correctly with 12 months of data
- [ ] Search returns results in < 300 ms on 10,000+ record DB
- [ ] Attachment storage size warning implemented

---

## Version 3.0 — Intelligence
**Target:** AI-powered features and smart import.

### Planned Features
- [ ] **OCR receipt scan** — camera captures receipt → auto-fill amount, date, merchant
- [ ] **SMS import** — parse bank SMS for automatic transaction creation
- [ ] **AI spending insights** — "You spent 40% more on Food this month"
- [ ] **Smart categorization** — auto-assign category based on description history
- [ ] **Budget suggestions** — recommend budget amounts based on spending history
- [ ] **Tablet layout** — adaptive two-pane layout

### Dependencies (external)
- OCR: Google ML Kit (`google_mlkit_text_recognition`)
- SMS: `telephony` package (Android) + manual entry fallback (iOS restriction)
- AI insights: On-device rule engine (no cloud API to maintain privacy)

### Release Checklist
- [ ] OCR accuracy > 85% on standard receipts
- [ ] SMS parser handles top 5 Indian bank formats
- [ ] No network calls for AI insights (fully on-device)

---

## Platform Expansion (Post v3.0)
- [ ] Tablet layout (adaptive `NavigationRail` for wide screens)
- [ ] macOS desktop (Flutter desktop target)
- [ ] Windows desktop
- [ ] Web (PWA, read-only view of backed-up data)

---

## Architecture Constraints (All Versions)
| Constraint | Requirement |
|---|---|
| No backend server | ✅ Always |
| No central database | ✅ Always |
| Works 100% offline | ✅ Always |
| User owns backup | ✅ Drive = user's own account |
| Max transaction capacity | 50,000+ (with proper indexes) |
| Min Android API | 21 (Android 5.0) |
| Min iOS | 13 |
