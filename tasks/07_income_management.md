# Task 07 — Income Management (Module 7)

## Goal
Track all income sources with categorization and wallet linkage.

---

## Database Table
```sql
CREATE TABLE income (
  id            TEXT PRIMARY KEY,
  amount        REAL NOT NULL,
  category      TEXT NOT NULL,     -- salary | freelance | interest | rent_received | business | gift | other
  description   TEXT,
  date          TEXT NOT NULL,
  wallet_id     TEXT NOT NULL,
  folder_id     TEXT,
  contact_id    TEXT,
  notes         TEXT,
  is_recurring  INTEGER DEFAULT 0,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  FOREIGN KEY (wallet_id) REFERENCES wallets(id),
  FOREIGN KEY (folder_id) REFERENCES folders(id),
  FOREIGN KEY (contact_id) REFERENCES contacts(id)
);
```

---

## Tasks

### Model
- [x] `Income` model with `fromMap` / `toMap`
- [x] `IncomeCategory` enum: salary, freelance, interest, rentReceived, business, gift, other
- [x] Same `tags` and `attachments` support as expenses (reuse `expense_tags` table with `income` prefix or unified `entity_tags`)

### Repository
- [x] `IncomeRepository`:
  - [x] `getAllIncome({DateTime? from, DateTime? to}) → List<Income>`
  - [x] `getIncomeById(String id) → Income?`
  - [x] `getTotalIncomeForPeriod(DateTime from, DateTime to) → double`
  - [x] `getIncomeForMonth(int year, int month) → List<Income>`
  - [x] `createIncome(Income)`
  - [x] `updateIncome(Income)`
  - [x] `deleteIncome(String id)`

### Income List Screen
- [x] Grouped by date
- [x] Each row: category icon, description, amount (green), wallet
- [x] Filter by category, wallet, date range
- [x] Swipe to delete

### Add / Edit Income Screen
- [x] Amount (required)
- [x] Category selector
- [x] Description
- [x] Date & time picker
- [x] Wallet selector
- [x] Folder selector (optional)
- [x] Contact linker (optional — e.g., received from a contact)
- [x] Notes
- [x] Attachments (salary slip image)
- [x] Save → validate → `createIncome`

### Providers
- [x] `incomeListProvider` — filtered `FutureProvider<List<Income>>`
- [x] `totalIncomeProvider` — `FutureProvider<double>` for dashboard
- [x] `monthIncomeProvider(year, month)` — for reports

---

## Acceptance Criteria
- Income adds to linked wallet balance
- Income and expense totals both appear on dashboard
- All CRUD operations work offline
