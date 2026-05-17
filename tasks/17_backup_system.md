# Task 17 — Backup System (Module 17)

## Goal
Let users back up their entire app data (database + attachments + config) to their personal Google Drive account and restore it on any device.

---

## Tasks

### Google Sign-In Setup
- [x] Add `google_sign_in` and `googleapis` to `pubspec.yaml`
- [x] Configure OAuth 2.0 client ID:
  - [x] Android: `google-services.json` in `android/app/`
  - [x] iOS: `GoogleService-Info.plist` in `ios/Runner/`
- [x] Requested scopes: `drive.file` (access only files created by this app)
- [x] `GoogleAuthService`:
  - [x] `signIn() → GoogleSignInAccount?`
  - [x] `signOut()`
  - [x] `getAuthHeaders() → Map<String, String>`
  - [x] `isSignedIn() → bool`

### Backup File Structure
```
app_backup_{timestamp}/
├── database.db          ← full SQLite copy
├── attachments/         ← all attachment files (preserving subfolder structure)
│   ├── expense/{id}/
│   └── income/{id}/
├── config.json          ← user profile + settings (non-sensitive)
└── metadata.json        ← backup version, app version, device info, created_at
```

### Encryption
- [x] Use `encrypt` package (AES-256-CBC)
- [x] Derive encryption key from user's PIN hash (never transmit key)
- [x] Encrypt `database.db` before upload
- [x] Store IV alongside encrypted file (not secret, but needed for decryption)
- [x] `EncryptionService`:
  - [x] `encryptFile(File input, String key) → File`
  - [x] `decryptFile(File input, String key) → File`

### Backup Service
- [x] `BackupService`:
  - [x] `createBackup() → BackupResult`
    1. Close any open DB write transactions
    2. Copy `database.db` to temp dir
    3. Encrypt DB copy
    4. Copy all attachments to temp zip staging
    5. Write `config.json` and `metadata.json`
    6. Zip everything into `pocket_ledger_backup_{timestamp}.zip.enc`
    7. Upload zip to Google Drive folder `PocketLedger/`
    8. Clean up temp files
  - [x] `restoreBackup(String driveFileId) → RestoreResult`
    1. Download zip from Drive to temp dir
    2. Verify `metadata.json` version compatibility
    3. Prompt PIN (for decryption key)
    4. Decrypt and unzip
    5. Replace local `database.db`
    6. Copy attachments (merge, not overwrite)
    7. Reload app providers
  - [x] `listBackups() → List<BackupMeta>` — list files in Drive `PocketLedger/` folder
  - [x] `deleteBackup(String driveFileId)`

### Google Drive API Calls
- [x] `DriveService`:
  - [x] `uploadFile(File localFile, String remoteName, String folderId) → String` (returns file ID)
  - [x] `downloadFile(String fileId, File destination)`
  - [x] `listFiles(String folderId) → List<DriveFile>`
  - [x] `createFolder(String name) → String` (creates `PocketLedger/` if not exists)
  - [x] `deleteFile(String fileId)`
  - [x] Handle `403 / 401` errors → re-trigger sign-in

### Backup Settings Screen
- [x] Google account sign-in section (avatar, email, sign out)
- [x] Auto-backup toggle
- [x] Backup frequency: Daily / Weekly / Monthly
- [x] "Backup Now" button (shows progress dialog)
- [x] Last backup time display
- [x] Backup size indicator

### Restore Screen
- [x] List of available backups in Drive (date, size, app version)
- [x] "Restore" button on each → confirm dialog → PIN prompt → restore
- [x] Progress indicator during restore
- [x] "Restore complete — restart app" dialog

### Auto-Backup Scheduling
- [x] Use `WorkManager` (Android) / `BGTaskScheduler` (iOS) via `workmanager` Flutter package
- [x] Schedule periodic task matching user's frequency preference
- [x] Auto-backup only if signed in and connected to WiFi (configurable)

### Backup Metadata (`metadata.json`)
```json
{
  "backup_version": 1,
  "app_version": "1.0.0",
  "created_at": "2026-05-01T12:00:00Z",
  "device": "Android",
  "record_counts": {
    "expenses": 1234,
    "income": 456,
    "loans": 12
  }
}
```

### Version History
- [x] Keep last 5 backups in Drive (delete oldest when creating new)
- [x] Show version list in Restore screen

---

## Edge Cases & Error Handling

### Network & Drive API
- [x] Network lost mid-upload → catch `SocketException` / `TimeoutException` → retry up to 3 times with exponential backoff (2 s, 4 s, 8 s)
- [x] Drive storage quota exceeded → show error: "Your Google Drive is full. Free up space and try again." — never leave partial file in Drive
- [x] Auth token expired mid-backup → silently refresh token and resume; if refresh fails → prompt re-sign-in
- [x] Drive folder `PocketLedger/` deleted by user → recreate on next backup, do not crash
- [x] File upload succeeds but metadata write to `backup_metadata` fails → retry metadata write; backup file is not orphaned

### Restore Edge Cases
- [x] Backup from newer app version (schema version N) restored on older app (schema version N-1) → show error: "This backup requires app version X or later. Please update the app."
- [x] Backup file corrupted (wrong checksum) → fail fast with clear error; do NOT overwrite local DB
- [x] Wrong PIN entered for decryption → `DecryptionException` caught → show "Incorrect PIN — cannot restore" without crashing
- [x] Restore interrupted (app killed) → DB is in temp location until fully written; only swap atomically (rename temp file over live file)
- [x] Restore when local DB has newer data → show conflict warning: "Restoring will overwrite X local changes made since last backup. Continue?" with cancel option

### Backup Integrity
- [x] Compute SHA-256 checksum of DB file before upload; store in `metadata.json`
- [x] On restore, verify checksum before decrypting — fail if mismatch

### Attachment Handling During Backup
- [x] Skip attachments > 50 MB total in a single backup run → warn user: "X large files skipped. Back them up manually."
- [x] Use streaming zip (not in-memory) to handle large attachment sets without OOM
- [x] On restore, only overwrite attachment if local copy is missing (avoid re-downloading unchanged files)

### Auto-Backup Reliability
- [x] WorkManager task: always check sign-in status before starting; skip silently if not signed in
- [x] If auto-backup fails 3 consecutive times → show persistent notification: "Auto-backup failed — tap to retry"
- [x] Record last N backup results (success/failure) in `backup_metadata` for user visibility

### Privacy & Security
- [x] `config.json` must never contain `pin_hash` or `recovery_phrase_hash`
- [x] Encryption key derived from PIN hash is zeroed from memory after use (use `Uint8List.fillRange(0, len, 0)`)
- [x] Temp backup files deleted from local storage regardless of success or failure (use `try/finally`)

---

## UI Micro-Interactions
- [x] "Backup Now" button: becomes progress indicator with animated Drive icon + "Encrypting… Uploading… Done"
- [x] Backup progress: show bytes uploaded / total (from Drive API upload progress stream)
- [x] Success state: green checkmark + "Backup complete" with timestamp
- [x] Last backup row in settings: relative time ("3 hours ago") not absolute timestamp
- [x] Restore screen: each backup card shows record counts ("1,234 expenses, 56 income") from `metadata.json`

---

## Acceptance Criteria
- Backup uploads successfully to user's Drive with correct structure
- Restore replaces local DB and attachments correctly
- Encryption key is never transmitted or stored in plaintext
- Auto-backup fires on schedule without user interaction
- App recovers gracefully from Drive API errors (network loss, auth expiry)
- Partial/corrupt backup never overwrites a good local DB
