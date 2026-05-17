# Task 02 — Authentication & Security (Module 2)

## Goal
Secure the app with a local PIN and optional biometrics. No server required.

---

## Database Table
```sql
CREATE TABLE security_settings (
  id              INTEGER PRIMARY KEY,
  pin_hash        TEXT NOT NULL,
  biometric_enabled INTEGER DEFAULT 0,
  recovery_phrase TEXT NOT NULL,
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL
);
```

---

## Tasks

### PIN Setup
- [x] PIN entry widget — 6-digit numeric keypad
- [x] Hash PIN using SHA-256 (`crypto` package) before storing
- [x] Confirm PIN screen (enter twice)
- [x] Store `pin_hash` in `security_settings`
- [x] Show PIN setup during onboarding (mandatory)

### PIN Lock Screen
- [x] Show on every app resume (after N minutes configurable: 0/1/5/15)
- [x] Numeric keypad with backspace
- [x] Attempt counter — after 5 failed attempts, show recovery phrase screen
- [x] "Use biometrics" button (shown only if biometrics enrolled)

### Biometric Unlock
- [x] Use `local_auth` to check if biometrics available (`canCheckBiometrics`)
- [x] Support fingerprint (Android/iOS) and Face ID (iOS)
- [x] Prompt biometric on lock screen if `biometric_enabled = 1`
- [x] Fall back to PIN if biometric fails

### Forgot PIN — Recovery via Phrase
- [x] During setup, generate a 12-word recovery phrase (BIP-39-style wordlist or custom)
- [x] Show phrase once, ask user to write it down, require confirmation of 3 random words
- [x] Store `recovery_phrase` (hashed or encrypted) in `security_settings`
- [x] On "Forgot PIN" flow: user enters all 12 words → verified → allowed to set new PIN

### App Resume Lock
- [x] Track last active timestamp using `AppLifecycleListener`
- [x] On foreground: compare elapsed time vs lock-after preference
- [x] If elapsed > threshold → show PIN lock screen

### Security Repository
- [x] `SecurityRepository` class with:
  - [x] `setupPin(String pin, String phrase)`
  - [x] `verifyPin(String pin) → bool`
  - [x] `setBiometricEnabled(bool)`
  - [x] `verifyRecoveryPhrase(String phrase) → bool`
  - [x] `resetPin(String newPin)`

### Providers
- [x] `securityProvider` — `StateNotifierProvider<SecurityNotifier>`
- [x] `isAuthenticatedProvider` — `StateProvider<bool>`
- [x] `lockAfterMinutesProvider` — derived from settings

---

## Edge Cases & Error Handling

### PIN Edge Cases
- [x] User force-quits app during PIN confirm screen → restart shows PIN setup again (no partial record)
- [x] Two concurrent PIN change requests (shouldn't happen in single-user app, but handle via mutex)
- [x] Device has no secure storage → fall back to storing pin_hash in SQLite only (already the default)
- [x] PIN entry with hardware keyboard (external keyboard on tablets) must work same as soft keypad

### Biometric Edge Cases
- [x] Biometric enrolled after app install → user enables toggle → works on next lock
- [x] User removes all fingerprints from device settings → `canCheckBiometrics` returns false → auto-disable biometric toggle, notify user
- [x] Biometric API returns `PlatformException` (e.g., hardware error) → log error, fall back silently to PIN
- [x] Face ID interrupted (phone tilts) → biometric prompt re-shown once; after 2 failures → fall back to PIN

### Recovery Phrase Edge Cases
- [x] User skips writing down phrase during setup → show persistent reminder badge in settings for 7 days
- [x] Phrase verification during forgot-PIN: normalize input (trim whitespace, lowercase) before comparing
- [x] Words entered in wrong order → reject with "Incorrect order" message (not just "wrong phrase")
- [x] Phrase regeneration: require current PIN before allowing regeneration

### Lock Screen Edge Cases
- [x] App in split-screen / PiP mode → lock timer still active
- [x] Device screen locked by OS (power button) → counts as backgrounding; app locks on return
- [x] Incoming call interrupts app → on return, respect lock timer (if ≥ threshold, lock)
- [x] Lock screen must block Android back button (no navigating past it)

### Security Anti-Patterns to Avoid
- [x] Never log PIN or recovery phrase, even in debug mode
- [x] Never store raw PIN in `SharedPreferences` or any unencrypted store
- [x] PIN hash must use SHA-256 with a per-device salt (stored in `flutter_secure_storage`)
- [x] Recovery phrase must be shown only once at setup; never retrievable in full after that (only verification)

---

## UI Micro-Interactions
- [x] Wrong PIN: keypad shakes horizontally (400 ms animation) + haptic error feedback
- [x] PIN dot fills with spring animation when digit entered
- [x] Biometric icon pulses gently while waiting for scan
- [x] Correct PIN: brief green flash on all dots before navigation
- [x] Lock countdown: if lock_after_minutes > 0, show subtle status bar indicator "Locks in Xs" when idle

---

## Acceptance Criteria
- PIN is hashed with SHA-256 + per-device salt; never stored in plaintext
- Biometric unlock works on supported devices with graceful fallback
- 5 wrong PINs → recovery phrase required to reset
- App locks after configurable idle time
- Removing all device fingerprints auto-disables biometric in app settings
