# Task 18 — Sync Engine (Module 18)

## Goal
Detect local changes, perform incremental backups, and resolve conflicts when restoring from a backup made on another device.

---

## Tasks

### Change Tracking Table
```sql
CREATE TABLE change_log (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_type TEXT NOT NULL,   -- expense | income | loan | wallet | folder | ...
  entity_id   TEXT NOT NULL,
  operation   TEXT NOT NULL,   -- insert | update | delete
  changed_at  TEXT NOT NULL,   -- ISO 8601 UTC
  synced      INTEGER DEFAULT 0
);
```
- [ ] Add SQLite triggers for each major table to auto-insert into `change_log` on INSERT / UPDATE / DELETE
- [ ] Example trigger:
  ```sql
  CREATE TRIGGER expenses_after_insert
  AFTER INSERT ON expenses
  BEGIN
    INSERT INTO change_log(entity_type, entity_id, operation, changed_at)
    VALUES ('expense', NEW.id, 'insert', datetime('now'));
  END;
  ```
- [ ] Create triggers for: `expenses`, `income`, `loans`, `loan_payments`, `wallets`, `folders`, `contacts`, `groups`, `group_transactions`, `budgets`

### Change Detection Service
- [ ] `ChangeDetectionService`:
  - [ ] `getUnsynced() → List<ChangeLog>` — rows where `synced = 0`
  - [ ] `markSynced(List<int> ids)` — set `synced = 1`
  - [ ] `hasUnsynced() → bool` — quick check for pending changes
  - [ ] `countUnsynced() → int`

### Incremental Backup Logic
- [ ] On backup trigger:
  1. Check `hasUnsynced()` — skip if nothing changed
  2. Fetch unsynced change log entries
  3. For each changed `entity_id`, extract full record from its table
  4. Build incremental patch JSON:
     ```json
     {
       "backup_version": 1,
       "incremental": true,
       "base_backup_id": "drive_file_id_of_last_full_backup",
       "changes": [
         { "entity_type": "expense", "entity_id": "uuid", "operation": "update", "data": {...} }
       ]
     }
     ```
  5. Upload patch file to Drive
  6. Mark change log entries as synced
- [ ] Full backup still done weekly (or on demand); incremental done on daily schedule

### Conflict Resolution
- [ ] Conflict scenario: backup from device A restored on device B which has newer local data
- [ ] Detection: compare `changed_at` timestamps from both sides
- [ ] Resolution strategy: **Last Write Wins** (higher `updated_at` timestamp wins)
- [ ] `ConflictResolver`:
  - [ ] `resolve(localRecord, remoteRecord) → Record` — returns winner
  - [ ] Log all conflicts to `conflict_log` table for user inspection (optional v2)

### Conflict Log Table
```sql
CREATE TABLE conflict_log (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_type     TEXT,
  entity_id       TEXT,
  local_updated   TEXT,
  remote_updated  TEXT,
  resolution      TEXT,   -- local_won | remote_won
  resolved_at     TEXT
);
```

### Sync Status UI
- [ ] Settings > Backup: show sync status chip:
  - `Up to date` (all synced)
  - `X changes pending` (unsynced count)
  - `Syncing...` (spinner during upload)
- [ ] Tap chip → Sync detail screen showing pending change entities

### Manual Sync Trigger
- [ ] "Sync Now" button in Settings > Backup
- [ ] Runs full backup if >7 days since last full, else incremental

### Providers
- [ ] `syncStatusProvider` — `StateNotifierProvider<SyncStatusNotifier>`
- [ ] `unsyncedCountProvider` — `StreamProvider<int>` (watches `change_log`)

---

## Acceptance Criteria
- Triggers automatically log all data changes to `change_log`
- Incremental backup only uploads changed records
- Conflicts resolved deterministically by `updated_at` timestamp
- Sync status badge updates in real time in the UI
