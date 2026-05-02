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
- [ ] `Income` model with `fromMap` / `toMap`
- [ ] `IncomeCategory` enum: salary, freelance, interest, rentReceived, business, gift, other
- [ ] Same `tags` and `attachments` support as expenses (reuse `expense_tags` table with `income` prefix or unified `entity_tags`)

### Repository
- [ ] `IncomeRepository`:
  - [ ] `getAllIncome({DateTime? from, DateTime? to}) → List<Income>`
  - [ ] `getIncomeById(String id) → Income?`
  - [ ] `getTotalIncomeForPeriod(DateTime from, DateTime to) → double`
  - [ ] `getIncomeForMonth(int year, int month) → List<Income>`
  - [ ] `createIncome(Income)`
  - [ ] `updateIncome(Income)`
  - [ ] `deleteIncome(String id)`

### Income List Screen
- [ ] Grouped by date
- [ ] Each row: category icon, description, amount (green), wallet
- [ ] Filter by category, wallet, date range
- [ ] Swipe to delete

### Add / Edit Income Screen
- [ ] Amount (required)
- [ ] Category selector
- [ ] Description
- [ ] Date & time picker
- [ ] Wallet selector
- [ ] Folder selector (optional)
- [ ] Contact linker (optional — e.g., received from a contact)
- [ ] Notes
- [ ] Attachments (salary slip image)
- [ ] Save → validate → `createIncome`

### Providers
- [ ] `incomeListProvider` — filtered `FutureProvider<List<Income>>`
- [ ] `totalIncomeProvider` — `FutureProvider<double>` for dashboard
- [ ] `monthIncomeProvider(year, month)` — for reports

---

## Acceptance Criteria
- Income adds to linked wallet balance
- Income and expense totals both appear on dashboard
- All CRUD operations work offline
