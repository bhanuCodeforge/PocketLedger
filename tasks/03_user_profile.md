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
- [x] `UserProfile` Dart model with `fromMap` / `toMap`
- [x] Default values matching table defaults

### Profile Repository
- [x] `UserProfileRepository`:
  - [x] `getProfile() → UserProfile?`
  - [x] `createProfile(UserProfile)`
  - [x] `updateProfile(UserProfile)`

### Profile Setup Screen (Onboarding Step)
- [x] Name input (optional, shown as "Hi, [name]" on dashboard)
- [x] Currency selector:
  - [x] Preset list: INR (₹), USD ($), AED (د.إ), EUR (€), GBP (£), JPY (¥)
  - [x] Custom currency option (name + symbol input)
  - [x] Searchable list
- [x] Language selector (English default; prepare i18n scaffold for future)
- [x] Timezone auto-detect from device (`DateTime.now().timeZoneName`)

### Profile Edit Screen (from Settings)
- [x] Same fields as setup
- [x] Save button triggers `updateProfile`
- [x] Currency change shows warning: "Existing transactions will show new symbol"

### Currency Formatting Utility
- [x] `CurrencyFormatter.format(double amount, UserProfile profile)` → `String`
- [x] Handles decimal places (0 for JPY, 2 for most)

### Providers
- [x] `userProfileProvider` — `StateNotifierProvider<UserProfileNotifier>`
- [x] `currencyProvider` — derived from profile
- [x] `themeProvider` — derived from profile (`theme_mode`)

---

## Acceptance Criteria
- Profile persists across app restarts
- Currency symbol shows correctly on all money fields
- Language code stored for future localization
- Timezone used for grouping transactions by day
