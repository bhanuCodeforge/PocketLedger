# Task 03 — User Profile (Module 3)

## Goal
Store and manage the user's personal preferences: name, currency, language, timezone, backup preferences.

---

## Database Table
```sql
CREATE TABLE user_profile (
  id                INTEGER PRIMARY KEY,
  name              TEXT,
  currency_code     TEXT DEFAULT 'INR',
  currency_symbol   TEXT DEFAULT '₹',
  language_code     TEXT DEFAULT 'en',
  timezone          TEXT DEFAULT 'Asia/Kolkata',
  theme_mode        TEXT DEFAULT 'system',
  lock_after_minutes INTEGER DEFAULT 5,
  backup_enabled    INTEGER DEFAULT 0,
  backup_frequency  TEXT DEFAULT 'daily',
  created_at        TEXT NOT NULL,
  updated_at        TEXT NOT NULL
);
```

---

## Tasks

### Profile Model
- [ ] `UserProfile` Dart model with `fromMap` / `toMap`
- [ ] Default values matching table defaults

### Profile Repository
- [ ] `UserProfileRepository`:
  - [ ] `getProfile() → UserProfile?`
  - [ ] `createProfile(UserProfile)`
  - [ ] `updateProfile(UserProfile)`

### Profile Setup Screen (Onboarding Step)
- [ ] Name input (optional, shown as "Hi, [name]" on dashboard)
- [ ] Currency selector:
  - [ ] Preset list: INR (₹), USD ($), AED (د.إ), EUR (€), GBP (£), JPY (¥)
  - [ ] Custom currency option (name + symbol input)
  - [ ] Searchable list
- [ ] Language selector (English default; prepare i18n scaffold for future)
- [ ] Timezone auto-detect from device (`DateTime.now().timeZoneName`)

### Profile Edit Screen (from Settings)
- [ ] Same fields as setup
- [ ] Save button triggers `updateProfile`
- [ ] Currency change shows warning: "Existing transactions will show new symbol"

### Currency Formatting Utility
- [ ] `CurrencyFormatter.format(double amount, UserProfile profile)` → `String`
- [ ] Handles decimal places (0 for JPY, 2 for most)

### Providers
- [ ] `userProfileProvider` — `StateNotifierProvider<UserProfileNotifier>`
- [ ] `currencyProvider` — derived from profile
- [ ] `themeProvider` — derived from profile (`theme_mode`)

---

## Acceptance Criteria
- Profile persists across app restarts
- Currency symbol shows correctly on all money fields
- Language code stored for future localization
- Timezone used for grouping transactions by day
