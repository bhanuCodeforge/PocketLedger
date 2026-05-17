# Task 19 — Settings (Module 19)

## Goal
Central settings screen for all app preferences: theme, security, currency, language, backup, export, and data management.

---

## Tasks

### Settings Screen Layout
Grouped sections:
1. **Profile** — name, currency, language, timezone
2. **Security** — PIN change, biometrics, lock timeout
3. **Appearance** — theme mode, accent color
4. **Backup & Sync** — Google account, frequency, last backup
5. **Notifications** — toggle per type, quiet hours
6. **Export** — PDF / CSV / Excel
7. **Data** — clear cache, delete all data, DB stats
8. **About** — app version, licenses, feedback

---

### Section: Profile
- [x] Tap to open User Profile edit screen (Module 3)
- [x] Display: name, currency symbol, language

### Section: Security
- [x] **Change PIN** — current PIN → new PIN → confirm new PIN
- [x] **Biometric unlock** toggle (only shown if device supports it)
- [x] **Lock after** — selector: Immediately / 1 min / 5 min / 15 min / Never
- [x] **Recovery phrase** — view (requires PIN auth) / regenerate

### Section: Appearance
- [x] **Theme** — radio: Light / Dark / System
  - [x] Immediate preview on tap
  - [x] Persist to `user_profile.theme_mode`
- [x] **Accent color** — color picker (8 preset colors)

### Section: Backup & Sync
- [x] Google account row: avatar + email (if signed in) or "Sign in with Google"
- [x] **Auto-backup** toggle
- [x] **Backup frequency** — Daily / Weekly / Monthly (shown only when auto-backup ON)
- [x] **Backup on WiFi only** toggle
- [x] **Last backup** — date/time or "Never"
- [x] **Backup Now** button → progress dialog → success/error snackbar
- [x] **Restore** → navigate to Restore screen (Module 17)
- [x] **Manage backups** → list in Google Drive

### Section: Notifications
- [x] Master enable/disable toggle
- [x] Loan due reminders toggle + lead time picker
- [x] Budget alert toggle
- [x] **Quiet hours** — enable toggle + start time + end time picker

### Section: Export
- [x] **Export format** — toggle: PDF / CSV / Excel
- [x] **Export period** — This Month / Last Month / This Year / Custom Range
- [x] **Export Now** button → triggers Module 20 flow

### Section: Data
- [x] **Clear cache** — deletes temp files, orphan attachments; shows freed MB
- [x] **Database stats** — total records per table, DB file size, attachment storage size
- [x] **Export entire DB** — raw `.db` file share (for debugging)
- [x] **Delete all data** — danger zone, requires PIN + type "DELETE" confirmation
  - Clears all tables, deletes all attachments, resets to onboarding

### Section: About
- [x] App version + build number
- [x] Open-source licenses (Flutter's built-in `showLicensePage`)
- [x] Rate app (opens Store)
- [x] Send feedback (opens email client)
- [x] Privacy policy link

### Settings Persistence
- [x] All settings read from / written to `user_profile` table or `security_settings` table
- [x] No shared preferences used (all in SQLite for backup consistency)

### Providers
- [x] `settingsProvider` — `StateNotifierProvider` wrapping `UserProfile`
- [x] All existing providers (`themeProvider`, `securityProvider`, `notificationSettingsProvider`) refreshed on settings change

---

## Acceptance Criteria
- Theme changes take effect immediately without app restart
- PIN change requires current PIN verification before allowing new PIN
- "Delete all data" is irreversible and requires double confirmation
- All settings survive app restart (read from DB on launch)
