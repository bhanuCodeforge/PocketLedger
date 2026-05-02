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
- [ ] Tap to open User Profile edit screen (Module 3)
- [ ] Display: name, currency symbol, language

### Section: Security
- [ ] **Change PIN** — current PIN → new PIN → confirm new PIN
- [ ] **Biometric unlock** toggle (only shown if device supports it)
- [ ] **Lock after** — selector: Immediately / 1 min / 5 min / 15 min / Never
- [ ] **Recovery phrase** — view (requires PIN auth) / regenerate

### Section: Appearance
- [ ] **Theme** — radio: Light / Dark / System
  - [ ] Immediate preview on tap
  - [ ] Persist to `user_profile.theme_mode`
- [ ] **Accent color** — color picker (8 preset colors)

### Section: Backup & Sync
- [ ] Google account row: avatar + email (if signed in) or "Sign in with Google"
- [ ] **Auto-backup** toggle
- [ ] **Backup frequency** — Daily / Weekly / Monthly (shown only when auto-backup ON)
- [ ] **Backup on WiFi only** toggle
- [ ] **Last backup** — date/time or "Never"
- [ ] **Backup Now** button → progress dialog → success/error snackbar
- [ ] **Restore** → navigate to Restore screen (Module 17)
- [ ] **Manage backups** → list in Google Drive

### Section: Notifications
- [ ] Master enable/disable toggle
- [ ] Loan due reminders toggle + lead time picker
- [ ] Budget alert toggle
- [ ] **Quiet hours** — enable toggle + start time + end time picker

### Section: Export
- [ ] **Export format** — toggle: PDF / CSV / Excel
- [ ] **Export period** — This Month / Last Month / This Year / Custom Range
- [ ] **Export Now** button → triggers Module 20 flow

### Section: Data
- [ ] **Clear cache** — deletes temp files, orphan attachments; shows freed MB
- [ ] **Database stats** — total records per table, DB file size, attachment storage size
- [ ] **Export entire DB** — raw `.db` file share (for debugging)
- [ ] **Delete all data** — danger zone, requires PIN + type "DELETE" confirmation
  - Clears all tables, deletes all attachments, resets to onboarding

### Section: About
- [ ] App version + build number
- [ ] Open-source licenses (Flutter's built-in `showLicensePage`)
- [ ] Rate app (opens Store)
- [ ] Send feedback (opens email client)
- [ ] Privacy policy link

### Settings Persistence
- [ ] All settings read from / written to `user_profile` table or `security_settings` table
- [ ] No shared preferences used (all in SQLite for backup consistency)

### Providers
- [ ] `settingsProvider` — `StateNotifierProvider` wrapping `UserProfile`
- [ ] All existing providers (`themeProvider`, `securityProvider`, `notificationSettingsProvider`) refreshed on settings change

---

## Acceptance Criteria
- Theme changes take effect immediately without app restart
- PIN change requires current PIN verification before allowing new PIN
- "Delete all data" is irreversible and requires double confirmation
- All settings survive app restart (read from DB on launch)
