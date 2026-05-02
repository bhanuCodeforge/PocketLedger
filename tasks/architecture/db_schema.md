# Architecture: Full Database Schema & ERD

All tables, columns, types, constraints, and foreign-key relationships for PocketLedger SQLite database.

---

## Table Inventory

| # | Table | Module |
|---|-------|--------|
| 1 | `user_profile` | 03 |
| 2 | `security_settings` | 02 |
| 3 | `wallets` | 04 |
| 4 | `folders` | 05 |
| 5 | `expenses` | 06 |
| 6 | `income` | 07 |
| 7 | `tags` | 06 |
| 8 | `entity_tags` | 06 |
| 9 | `attachments` | 16 |
| 10 | `loans` | 08 |
| 11 | `loan_payments` | 08 |
| 12 | `contacts` | 09 |
| 13 | `groups` | 10 |
| 14 | `group_members` | 10 |
| 15 | `group_transactions` | 10 |
| 16 | `group_transaction_splits` | 10 |
| 17 | `budgets` | 11 |
| 18 | `change_log` | 18 |
| 19 | `conflict_log` | 18 |
| 20 | `backup_metadata` | 17 |
| 21 | `recurring_rules` | 15 |
| 22 | `sms_import_log` | 22 |
| 23 | `ai_insights` | 23 |

---

## Full DDL

```sql
-- ─────────────────────────────────────────────
-- PRAGMA
-- ─────────────────────────────────────────────
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

-- ─────────────────────────────────────────────
-- 1. USER PROFILE
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_profile (
  id                  INTEGER PRIMARY KEY CHECK (id = 1), -- singleton row
  name                TEXT,
  currency_code       TEXT    NOT NULL DEFAULT 'INR',
  currency_symbol     TEXT    NOT NULL DEFAULT '₹',
  currency_decimals   INTEGER NOT NULL DEFAULT 2,
  language_code       TEXT    NOT NULL DEFAULT 'en',
  timezone            TEXT    NOT NULL DEFAULT 'Asia/Kolkata',
  theme_mode          TEXT    NOT NULL DEFAULT 'system'
                              CHECK (theme_mode IN ('light','dark','system')),
  accent_color        TEXT    DEFAULT '#2196F3',
  lock_after_minutes  INTEGER NOT NULL DEFAULT 5,
  backup_enabled      INTEGER NOT NULL DEFAULT 0,
  backup_frequency    TEXT    NOT NULL DEFAULT 'weekly'
                              CHECK (backup_frequency IN ('daily','weekly','monthly')),
  backup_wifi_only    INTEGER NOT NULL DEFAULT 1,
  last_backup_at      TEXT,
  created_at          TEXT    NOT NULL,
  updated_at          TEXT    NOT NULL
);

-- ─────────────────────────────────────────────
-- 2. SECURITY SETTINGS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS security_settings (
  id                    INTEGER PRIMARY KEY CHECK (id = 1),
  pin_hash              TEXT    NOT NULL,
  biometric_enabled     INTEGER NOT NULL DEFAULT 0,
  recovery_phrase_hash  TEXT    NOT NULL,
  failed_attempts       INTEGER NOT NULL DEFAULT 0,
  locked_until          TEXT,           -- ISO 8601, NULL if not locked
  created_at            TEXT    NOT NULL,
  updated_at            TEXT    NOT NULL
);

-- ─────────────────────────────────────────────
-- 3. WALLETS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS wallets (
  id              TEXT    PRIMARY KEY,  -- UUID v4
  name            TEXT    NOT NULL,
  type            TEXT    NOT NULL DEFAULT 'cash'
                          CHECK (type IN ('cash','bank','upi','credit_card','business','other')),
  opening_balance REAL    NOT NULL DEFAULT 0.0,
  color           TEXT    NOT NULL DEFAULT '#607D8B',
  icon            TEXT    NOT NULL DEFAULT 'account_balance_wallet',
  status          TEXT    NOT NULL DEFAULT 'active'
                          CHECK (status IN ('active','archived')),
  sort_order      INTEGER NOT NULL DEFAULT 0,
  created_at      TEXT    NOT NULL,
  updated_at      TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_wallets_status ON wallets(status);

-- ─────────────────────────────────────────────
-- 4. FOLDERS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS folders (
  id          TEXT    PRIMARY KEY,
  name        TEXT    NOT NULL,
  parent_id   TEXT    REFERENCES folders(id) ON DELETE SET NULL,
  color       TEXT    NOT NULL DEFAULT '#607D8B',
  icon        TEXT    NOT NULL DEFAULT 'folder',
  status      TEXT    NOT NULL DEFAULT 'active'
                      CHECK (status IN ('active','archived')),
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TEXT    NOT NULL,
  updated_at  TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_folders_parent ON folders(parent_id);
CREATE INDEX IF NOT EXISTS idx_folders_status ON folders(status);

-- ─────────────────────────────────────────────
-- 5. EXPENSES
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS expenses (
  id              TEXT    PRIMARY KEY,
  amount          REAL    NOT NULL CHECK (amount > 0),
  category        TEXT    NOT NULL,
  description     TEXT,
  date            TEXT    NOT NULL,   -- ISO 8601 with timezone
  wallet_id       TEXT    NOT NULL REFERENCES wallets(id),
  folder_id       TEXT    REFERENCES folders(id),
  contact_id      TEXT    REFERENCES contacts(id),
  payment_mode    TEXT    DEFAULT 'cash'
                          CHECK (payment_mode IN ('cash','card','upi','bank_transfer','other')),
  notes           TEXT,
  is_recurring    INTEGER NOT NULL DEFAULT 0,
  recurring_rule_id TEXT  REFERENCES recurring_rules(id),
  transfer_id     TEXT,               -- links to matching income for wallet transfers
  created_at      TEXT    NOT NULL,
  updated_at      TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_expenses_date       ON expenses(date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_wallet     ON expenses(wallet_id);
CREATE INDEX IF NOT EXISTS idx_expenses_folder     ON expenses(folder_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category   ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_contact    ON expenses(contact_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date_cat   ON expenses(date, category);

-- ─────────────────────────────────────────────
-- 6. INCOME
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS income (
  id              TEXT    PRIMARY KEY,
  amount          REAL    NOT NULL CHECK (amount > 0),
  category        TEXT    NOT NULL,
  description     TEXT,
  date            TEXT    NOT NULL,
  wallet_id       TEXT    NOT NULL REFERENCES wallets(id),
  folder_id       TEXT    REFERENCES folders(id),
  contact_id      TEXT    REFERENCES contacts(id),
  notes           TEXT,
  is_recurring    INTEGER NOT NULL DEFAULT 0,
  recurring_rule_id TEXT  REFERENCES recurring_rules(id),
  transfer_id     TEXT,
  created_at      TEXT    NOT NULL,
  updated_at      TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_income_date     ON income(date DESC);
CREATE INDEX IF NOT EXISTS idx_income_wallet   ON income(wallet_id);
CREATE INDEX IF NOT EXISTS idx_income_category ON income(category);

-- ─────────────────────────────────────────────
-- 7. TAGS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tags (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL UNIQUE COLLATE NOCASE
);

-- ─────────────────────────────────────────────
-- 8. ENTITY TAGS (unified: expenses + income)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS entity_tags (
  entity_id   TEXT NOT NULL,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('expense','income')),
  tag_id      TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (entity_id, entity_type, tag_id)
);

CREATE INDEX IF NOT EXISTS idx_entity_tags_tag ON entity_tags(tag_id);

-- ─────────────────────────────────────────────
-- 9. ATTACHMENTS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS attachments (
  id          TEXT    PRIMARY KEY,
  entity_id   TEXT    NOT NULL,
  entity_type TEXT    NOT NULL CHECK (entity_type IN ('expense','income','loan')),
  file_path   TEXT    NOT NULL,   -- relative to app documents dir
  file_name   TEXT    NOT NULL,
  file_type   TEXT    NOT NULL DEFAULT 'image'
                      CHECK (file_type IN ('image','pdf','other')),
  file_size   INTEGER NOT NULL DEFAULT 0,  -- bytes
  created_at  TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_attachments_entity ON attachments(entity_id, entity_type);

-- ─────────────────────────────────────────────
-- 10. CONTACTS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS contacts (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  phone       TEXT,
  email       TEXT,
  category    TEXT NOT NULL DEFAULT 'other'
                   CHECK (category IN ('friend','family','borrower','customer','other')),
  avatar_path TEXT,
  notes       TEXT,
  is_deleted  INTEGER NOT NULL DEFAULT 0,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_contacts_name ON contacts(name COLLATE NOCASE);

-- ─────────────────────────────────────────────
-- 11. LOANS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS loans (
  id              TEXT    PRIMARY KEY,
  contact_id      TEXT    NOT NULL REFERENCES contacts(id),
  type            TEXT    NOT NULL CHECK (type IN ('given','taken')),
  principal       REAL    NOT NULL CHECK (principal > 0),
  interest_rate   REAL    NOT NULL DEFAULT 0.0 CHECK (interest_rate >= 0),
  interest_type   TEXT    NOT NULL DEFAULT 'simple'
                          CHECK (interest_type IN ('simple','compound')),
  compound_freq   INTEGER NOT NULL DEFAULT 12, -- per year
  start_date      TEXT    NOT NULL,
  due_date        TEXT,
  status          TEXT    NOT NULL DEFAULT 'active'
                          CHECK (status IN ('active','overdue','settled')),
  wallet_id       TEXT    REFERENCES wallets(id),
  notes           TEXT,
  created_at      TEXT    NOT NULL,
  updated_at      TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_loans_contact   ON loans(contact_id);
CREATE INDEX IF NOT EXISTS idx_loans_due_date  ON loans(due_date);
CREATE INDEX IF NOT EXISTS idx_loans_status    ON loans(status);

-- ─────────────────────────────────────────────
-- 12. LOAN PAYMENTS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS loan_payments (
  id          TEXT    PRIMARY KEY,
  loan_id     TEXT    NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
  amount      REAL    NOT NULL CHECK (amount > 0),
  date        TEXT    NOT NULL,
  wallet_id   TEXT    REFERENCES wallets(id),
  notes       TEXT,
  created_at  TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_loan_payments_loan ON loan_payments(loan_id);

-- ─────────────────────────────────────────────
-- 13. GROUPS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS groups (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  description TEXT,
  icon        TEXT DEFAULT 'group',
  color       TEXT DEFAULT '#3F51B5',
  status      TEXT NOT NULL DEFAULT 'active'
                   CHECK (status IN ('active','settled','archived')),
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);

-- ─────────────────────────────────────────────
-- 14. GROUP MEMBERS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS group_members (
  id          TEXT PRIMARY KEY,
  group_id    TEXT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  contact_id  TEXT REFERENCES contacts(id),
  name        TEXT NOT NULL,
  is_self     INTEGER NOT NULL DEFAULT 0,  -- 1 = the app user
  created_at  TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_group_members_group ON group_members(group_id);

-- ─────────────────────────────────────────────
-- 15. GROUP TRANSACTIONS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS group_transactions (
  id              TEXT    PRIMARY KEY,
  group_id        TEXT    NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  description     TEXT    NOT NULL,
  total_amount    REAL    NOT NULL CHECK (total_amount > 0),
  date            TEXT    NOT NULL,
  paid_by_member  TEXT    NOT NULL REFERENCES group_members(id),
  split_type      TEXT    NOT NULL DEFAULT 'equal'
                          CHECK (split_type IN ('equal','custom','percentage')),
  notes           TEXT,
  created_at      TEXT    NOT NULL,
  updated_at      TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_group_txn_group ON group_transactions(group_id);

-- ─────────────────────────────────────────────
-- 16. GROUP TRANSACTION SPLITS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS group_transaction_splits (
  id              TEXT    PRIMARY KEY,
  transaction_id  TEXT    NOT NULL REFERENCES group_transactions(id) ON DELETE CASCADE,
  member_id       TEXT    NOT NULL REFERENCES group_members(id),
  amount          REAL    NOT NULL CHECK (amount >= 0),
  is_settled      INTEGER NOT NULL DEFAULT 0,
  settled_at      TEXT
);

CREATE INDEX IF NOT EXISTS idx_splits_transaction ON group_transaction_splits(transaction_id);
CREATE INDEX IF NOT EXISTS idx_splits_member      ON group_transaction_splits(member_id);

-- ─────────────────────────────────────────────
-- 17. BUDGETS
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS budgets (
  id                  TEXT    PRIMARY KEY,
  name                TEXT    NOT NULL,
  type                TEXT    NOT NULL CHECK (type IN ('monthly','folder','category')),
  amount              REAL    NOT NULL CHECK (amount > 0),
  month               INTEGER CHECK (month BETWEEN 1 AND 12),
  year                INTEGER,
  folder_id           TEXT    REFERENCES folders(id),
  category            TEXT,
  alert_50            INTEGER NOT NULL DEFAULT 1,
  alert_80            INTEGER NOT NULL DEFAULT 1,
  alert_100           INTEGER NOT NULL DEFAULT 1,
  last_alert_pct      INTEGER DEFAULT 0,  -- last threshold alerted (0/50/80/100)
  created_at          TEXT    NOT NULL,
  updated_at          TEXT    NOT NULL
);

-- ─────────────────────────────────────────────
-- 18. RECURRING RULES
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS recurring_rules (
  id              TEXT PRIMARY KEY,
  entity_type     TEXT NOT NULL CHECK (entity_type IN ('expense','income')),
  frequency       TEXT NOT NULL CHECK (frequency IN ('daily','weekly','monthly','yearly')),
  interval_value  INTEGER NOT NULL DEFAULT 1, -- every N frequency units
  next_due_date   TEXT NOT NULL,
  end_date        TEXT,
  is_active       INTEGER NOT NULL DEFAULT 1,
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL
);

-- ─────────────────────────────────────────────
-- 19. CHANGE LOG (sync engine)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS change_log (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_type TEXT    NOT NULL,
  entity_id   TEXT    NOT NULL,
  operation   TEXT    NOT NULL CHECK (operation IN ('insert','update','delete')),
  changed_at  TEXT    NOT NULL DEFAULT (datetime('now')),
  synced      INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_change_log_synced ON change_log(synced, changed_at);

-- ─────────────────────────────────────────────
-- 20. CONFLICT LOG
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS conflict_log (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_type     TEXT,
  entity_id       TEXT,
  local_updated   TEXT,
  remote_updated  TEXT,
  resolution      TEXT CHECK (resolution IN ('local_won','remote_won')),
  resolved_at     TEXT
);

-- ─────────────────────────────────────────────
-- 21. BACKUP METADATA
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS backup_metadata (
  id              TEXT    PRIMARY KEY,
  drive_file_id   TEXT    NOT NULL,
  backup_type     TEXT    NOT NULL CHECK (backup_type IN ('full','incremental')),
  file_size       INTEGER NOT NULL DEFAULT 0,
  record_count    INTEGER NOT NULL DEFAULT 0,
  app_version     TEXT    NOT NULL,
  created_at      TEXT    NOT NULL
);

-- ─────────────────────────────────────────────
-- 22. SMS IMPORT LOG
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sms_import_log (
  id              TEXT    PRIMARY KEY,
  sms_address     TEXT    NOT NULL,  -- sender number
  sms_body        TEXT    NOT NULL,
  parsed_amount   REAL,
  parsed_type     TEXT,              -- debit | credit
  parsed_merchant TEXT,
  linked_entity_id TEXT,             -- expense/income id if imported
  status          TEXT    NOT NULL DEFAULT 'pending'
                          CHECK (status IN ('pending','imported','skipped','failed')),
  created_at      TEXT    NOT NULL
);

-- ─────────────────────────────────────────────
-- 23. AI INSIGHTS CACHE
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ai_insights (
  id          TEXT    PRIMARY KEY,
  type        TEXT    NOT NULL,  -- spending_spike | budget_risk | saving_opportunity | anomaly
  title       TEXT    NOT NULL,
  body        TEXT    NOT NULL,
  data_json   TEXT,              -- supporting numbers as JSON
  is_read     INTEGER NOT NULL DEFAULT 0,
  valid_until TEXT    NOT NULL,  -- expire after period
  created_at  TEXT    NOT NULL
);
```

---

## Entity Relationship Summary

```
user_profile (1) ──── (1) security_settings

wallets (1) ──── (N) expenses
wallets (1) ──── (N) income
wallets (1) ──── (N) loans
wallets (1) ──── (N) loan_payments

folders (1) ──── (N) folders [self-referential, parent_id]
folders (1) ──── (N) expenses
folders (1) ──── (N) income
folders (1) ──── (N) budgets

contacts (1) ──── (N) expenses
contacts (1) ──── (N) income
contacts (1) ──── (N) loans
contacts (1) ──── (N) group_members

expenses (1) ──── (N) entity_tags ──── (N) tags
income   (1) ──── (N) entity_tags ──── (N) tags

expenses (1) ──── (N) attachments
income   (1) ──── (N) attachments
loans    (1) ──── (N) attachments

loans (1) ──── (N) loan_payments

groups (1) ──── (N) group_members
groups (1) ──── (N) group_transactions ──── (N) group_transaction_splits

budgets FK → folders
budgets FK → (category, inline string)

recurring_rules (1) ──── (N) expenses [via recurring_rule_id]
recurring_rules (1) ──── (N) income   [via recurring_rule_id]
```

---

## Migration Strategy

| Version | Changes |
|---------|---------|
| v1 | Initial schema (all tables above) |
| v2 | Add `recurring_rules`, `sms_import_log`, `ai_insights` |
| v3 | Add `conflict_log`, extend `backup_metadata` |

```dart
// DatabaseHelper.onUpgrade
switch (oldVersion) {
  case 1:
    await _migrateV1toV2(db);
    continue;
  case 2:
    await _migrateV2toV3(db);
    break;
}
```

- Never DROP columns (SQLite ALTER TABLE is limited)
- Always ADD COLUMN with a DEFAULT value
- Run `PRAGMA user_version = N` after each migration
