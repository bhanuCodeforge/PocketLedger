# Task 11 — Budget Management (Module 11)

## Goal
Set monthly, folder-level, and category-level budgets with threshold alerts.

---

## Database Table
```sql
CREATE TABLE budgets (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL,       -- monthly | folder | category
  amount      REAL NOT NULL,
  month       INTEGER,             -- 1–12 (for monthly budgets)
  year        INTEGER,             -- (for monthly budgets)
  folder_id   TEXT,                -- for folder budgets
  category    TEXT,                -- for category budgets
  alert_50    INTEGER DEFAULT 1,
  alert_80    INTEGER DEFAULT 1,
  alert_100   INTEGER DEFAULT 1,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL,
  FOREIGN KEY (folder_id) REFERENCES folders(id)
);
```

---

## Tasks

### Model
- [x] `Budget` model with `fromMap` / `toMap`
- [x] `BudgetType` enum: monthly, folder, category
- [x] Computed fields: `spent`, `remaining`, `percentUsed`

### Repository
- [x] `BudgetRepository`:
  - [x] `getAllBudgets() → List<Budget>`
  - [x] `getActiveBudgets() → List<Budget>` — current month + folder/category
  - [x] `getBudgetById(String id) → Budget?`
  - [x] `createBudget(Budget)`
  - [x] `updateBudget(Budget)`
  - [x] `deleteBudget(String id)`
  - [x] `getSpentForBudget(Budget) → double` — query expenses for matching scope + period

### Spent Calculation Logic
- [x] **Monthly budget:** SUM of expenses in `year=X, month=Y`
- [x] **Folder budget:** SUM of expenses in `folder_id=X` for current month
- [x] **Category budget:** SUM of expenses with `category=X` for current month
- [x] All calculations run via SQL aggregation, not in-memory

### Budget List Screen
- [x] Grouped: Monthly / Folder / Category sections
- [x] Each card: budget name, progress bar, spent/total, % used
- [x] Progress bar color: green (<50%), orange (50–79%), red (≥80%)
- [x] FAB to add budget

### Add / Edit Budget Screen
- [x] Budget type selector
- [x] Name (auto-filled from type selection)
- [x] Amount input
- [x] Type-specific fields:
  - [x] Monthly: month/year picker (default current)
  - [x] Folder: folder selector
  - [x] Category: category selector
- [x] Alert toggles: 50% / 80% / 100%
- [x] Save → `createBudget`

### Budget Alert Logic
- [x] After every expense addition, run `getSpentForBudget` for all affected budgets
- [x] If threshold crossed and not already alerted this session:
  - [x] Show in-app snackbar or banner: "Food budget 80% used"
  - [x] Schedule local notification (Module 15)
- [x] Track `last_alerted_threshold` in memory (not DB) to avoid repeated alerts per session

### Dashboard Widget
- [x] Show top 3 budgets by % used
- [x] Tap to go to Budget list

### Providers
- [x] `budgetsProvider` — `FutureProvider<List<Budget>>`
- [x] `budgetProgressProvider(budgetId)` — spent + percent
- [x] `budgetAlertsProvider` — budgets over alert thresholds

---

## Acceptance Criteria
- Budget spent amount matches actual expenses for scope and period
- Progress bars accurately reflect percentage used
- Alert fires exactly once per threshold crossing per session
- Multiple budget types coexist without conflict
