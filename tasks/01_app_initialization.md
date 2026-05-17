# Task 01 — App Initialization (Module 1)

## Goal
Handle launch sequence: splash → DB check → onboarding or PIN lock → dashboard.

---

## Tasks

### Splash Screen
- [x] Implement native splash using `flutter_native_splash`
- [x] Show app logo and name for 1.5–2 s
- [x] Run async init tasks during splash:
  - [x] Open SQLite database
  - [x] Load user profile from DB
  - [x] Determine first-time vs returning user
  - [x] Load theme preference

### Routing Decision
- [x] If first-time → navigate to Onboarding
- [x] If returning and PIN enabled → navigate to PIN Lock screen
- [x] If returning and no PIN → navigate to Dashboard

### Onboarding Flow (First-Time Only)
- [x] Screen 1: Welcome — app name, tagline, "Get Started" button
- [x] Screen 2: How it works — offline-first, your data, your backup
- [x] Screen 3: Currency selection (INR default, USD, AED, custom)
- [x] Screen 4: Create your wallet (at least one wallet required)
- [x] Screen 5: Set PIN (mandatory) → goes to Dashboard

### Permission Handling
- [x] Request storage permission on Android (for attachments and backup)
- [x] Request camera permission (for receipt images, deferred until first use)
- [x] Request notification permission (Android 13+, iOS)
- [x] Gracefully handle permission denial with retry/skip options

### Theme Initialization
- [x] Read theme mode (light/dark/system) from `user_profile` table on launch
- [x] Apply theme before first frame via `WidgetsBinding.instance.addPostFrameCallback`

### Providers
- [x] `appInitProvider` — `FutureProvider` that runs init sequence
- [x] `firstTimeProvider` — `StateProvider<bool>`
- [x] `themeProvider` — `StateNotifierProvider<ThemeNotifier>`

---

## Acceptance Criteria
- Cold launch shows splash, performs DB init, routes correctly
- First-time users complete onboarding and land on Dashboard
- Returning users see PIN lock before Dashboard
- Theme is applied before any UI is painted
