# Task 01 — App Initialization (Module 1)

## Goal
Handle launch sequence: splash → DB check → onboarding or PIN lock → dashboard.

---

## Tasks

### Splash Screen
- [ ] Implement native splash using `flutter_native_splash`
- [ ] Show app logo and name for 1.5–2 s
- [ ] Run async init tasks during splash:
  - [ ] Open SQLite database
  - [ ] Load user profile from DB
  - [ ] Determine first-time vs returning user
  - [ ] Load theme preference

### Routing Decision
- [ ] If first-time → navigate to Onboarding
- [ ] If returning and PIN enabled → navigate to PIN Lock screen
- [ ] If returning and no PIN → navigate to Dashboard

### Onboarding Flow (First-Time Only)
- [ ] Screen 1: Welcome — app name, tagline, "Get Started" button
- [ ] Screen 2: How it works — offline-first, your data, your backup
- [ ] Screen 3: Currency selection (INR default, USD, AED, custom)
- [ ] Screen 4: Create your wallet (at least one wallet required)
- [ ] Screen 5: Set PIN (mandatory) → goes to Dashboard

### Permission Handling
- [ ] Request storage permission on Android (for attachments and backup)
- [ ] Request camera permission (for receipt images, deferred until first use)
- [ ] Request notification permission (Android 13+, iOS)
- [ ] Gracefully handle permission denial with retry/skip options

### Theme Initialization
- [ ] Read theme mode (light/dark/system) from `user_profile` table on launch
- [ ] Apply theme before first frame via `WidgetsBinding.instance.addPostFrameCallback`

### Providers
- [ ] `appInitProvider` — `FutureProvider` that runs init sequence
- [ ] `firstTimeProvider` — `StateProvider<bool>`
- [ ] `themeProvider` — `StateNotifierProvider<ThemeNotifier>`

---

## Acceptance Criteria
- Cold launch shows splash, performs DB init, routes correctly
- First-time users complete onboarding and land on Dashboard
- Returning users see PIN lock before Dashboard
- Theme is applied before any UI is painted
