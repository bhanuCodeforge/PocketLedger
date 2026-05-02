# Task 17 — Backup System (Module 17)

## Goal
Let users back up their entire app data (database + attachments + config) to their personal Google Drive account and restore it on any device.

---

## Tasks

### Google Sign-In Setup
- [ ] Add `google_sign_in` and `googleapis` to `pubspec.yaml`
- [ ] Configure OAuth 2.0 client ID:
  - [ ] Android: `google-services.json` in `android/app/`
  - [ ] iOS: `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Requested scopes: `drive.file` (access only files created by this app)
- [ ] `GoogleAuthService`:
  - [ ] `signIn() → GoogleSignInAccount?`
  - [ ] `signOut()`
  - [ ] `getAuthHeaders() → Map<String, String>`
  - [ ] `isSignedIn() → bool`

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
- [ ] Use `encrypt` package (AES-256-CBC)
- [ ] Derive encryption key from user's PIN hash (never transmit key)
- [ ] Encrypt `database.db` before upload
- [ ] Store IV alongside encrypted file (not secret, but needed for decryption)
- [ ] `EncryptionService`:
  - [ ] `encryptFile(File input, String key) → File`
  - [ ] `decryptFile(File input, String key) → File`

### Backup Service
- [ ] `BackupService`:
  - [ ] `createBackup() → BackupResult`
    1. Close any open DB write transactions
    2. Copy `database.db` to temp dir
    3. Encrypt DB copy
    4. Copy all attachments to temp zip staging
    5. Write `config.json` and `metadata.json`
    6. Zip everything into `pocket_ledger_backup_{timestamp}.zip.enc`
    7. Upload zip to Google Drive folder `PocketLedger/`
    8. Clean up temp files
  - [ ] `restoreBackup(String driveFileId) → RestoreResult`
    1. Download zip from Drive to temp dir
    2. Verify `metadata.json` version compatibility
    3. Prompt PIN (for decryption key)
    4. Decrypt and unzip
    5. Replace local `database.db`
    6. Copy attachments (merge, not overwrite)
    7. Reload app providers
  - [ ] `listBackups() → List<BackupMeta>` — list files in Drive `PocketLedger/` folder
  - [ ] `deleteBackup(String driveFileId)`

### Google Drive API Calls
- [ ] `DriveService`:
  - [ ] `uploadFile(File localFile, String remoteName, String folderId) → String` (returns file ID)
  - [ ] `downloadFile(String fileId, File destination)`
  - [ ] `listFiles(String folderId) → List<DriveFile>`
  - [ ] `createFolder(String name) → String` (creates `PocketLedger/` if not exists)
  - [ ] `deleteFile(String fileId)`
  - [ ] Handle `403 / 401` errors → re-trigger sign-in

### Backup Settings Screen
- [ ] Google account sign-in section (avatar, email, sign out)
- [ ] Auto-backup toggle
- [ ] Backup frequency: Daily / Weekly / Monthly
- [ ] "Backup Now" button (shows progress dialog)
- [ ] Last backup time display
- [ ] Backup size indicator

### Restore Screen
- [ ] List of available backups in Drive (date, size, app version)
- [ ] "Restore" button on each → confirm dialog → PIN prompt → restore
- [ ] Progress indicator during restore
- [ ] "Restore complete — restart app" dialog

### Auto-Backup Scheduling
- [ ] Use `WorkManager` (Android) / `BGTaskScheduler` (iOS) via `workmanager` Flutter package
- [ ] Schedule periodic task matching user's frequency preference
- [ ] Auto-backup only if signed in and connected to WiFi (configurable)

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
- [ ] Keep last 5 backups in Drive (delete oldest when creating new)
- [ ] Show version list in Restore screen

---

## Edge Cases & Error Handling

### Network & Drive API
- [ ] Network lost mid-upload → catch `SocketException` / `TimeoutException` → retry up to 3 times with exponential backoff (2 s, 4 s, 8 s)
- [ ] Drive storage quota exceeded → show error: "Your Google Drive is full. Free up space and try again." — never leave partial file in Drive
- [ ] Auth token expired mid-backup → silently refresh token and resume; if refresh fails → prompt re-sign-in
- [ ] Drive folder `PocketLedger/` deleted by user → recreate on next backup, do not crash
- [ ] File upload succeeds but metadata write to `backup_metadata` fails → retry metadata write; backup file is not orphaned

### Restore Edge Cases
- [ ] Backup from newer app version (schema version N) restored on older app (schema version N-1) → show error: "This backup requires app version X or later. Please update the app."
- [ ] Backup file corrupted (wrong checksum) → fail fast with clear error; do NOT overwrite local DB
- [ ] Wrong PIN entered for decryption → `DecryptionException` caught → show "Incorrect PIN — cannot restore" without crashing
- [ ] Restore interrupted (app killed) → DB is in temp location until fully written; only swap atomically (rename temp file over live file)
- [ ] Restore when local DB has newer data → show conflict warning: "Restoring will overwrite X local changes made since last backup. Continue?" with cancel option

### Backup Integrity
- [ ] Compute SHA-256 checksum of DB file before upload; store in `metadata.json`
- [ ] On restore, verify checksum before decrypting — fail if mismatch

### Attachment Handling During Backup
- [ ] Skip attachments > 50 MB total in a single backup run → warn user: "X large files skipped. Back them up manually."
- [ ] Use streaming zip (not in-memory) to handle large attachment sets without OOM
- [ ] On restore, only overwrite attachment if local copy is missing (avoid re-downloading unchanged files)

### Auto-Backup Reliability
- [ ] WorkManager task: always check sign-in status before starting; skip silently if not signed in
- [ ] If auto-backup fails 3 consecutive times → show persistent notification: "Auto-backup failed — tap to retry"
- [ ] Record last N backup results (success/failure) in `backup_metadata` for user visibility

### Privacy & Security
- [ ] `config.json` must never contain `pin_hash` or `recovery_phrase_hash`
- [ ] Encryption key derived from PIN hash is zeroed from memory after use (use `Uint8List.fillRange(0, len, 0)`)
- [ ] Temp backup files deleted from local storage regardless of success or failure (use `try/finally`)

---

## UI Micro-Interactions
- [ ] "Backup Now" button: becomes progress indicator with animated Drive icon + "Encrypting… Uploading… Done"
- [ ] Backup progress: show bytes uploaded / total (from Drive API upload progress stream)
- [ ] Success state: green checkmark + "Backup complete" with timestamp
- [ ] Last backup row in settings: relative time ("3 hours ago") not absolute timestamp
- [ ] Restore screen: each backup card shows record counts ("1,234 expenses, 56 income") from `metadata.json`

---

## Acceptance Criteria
- Backup uploads successfully to user's Drive with correct structure
- Restore replaces local DB and attachments correctly
- Encryption key is never transmitted or stored in plaintext
- Auto-backup fires on schedule without user interaction
- App recovers gracefully from Drive API errors (network loss, auth expiry)
- Partial/corrupt backup never overwrites a good local DB
