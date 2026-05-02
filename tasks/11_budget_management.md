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
- [ ] `Budget` model with `fromMap` / `toMap`
- [ ] `BudgetType` enum: monthly, folder, category
- [ ] Computed fields: `spent`, `remaining`, `percentUsed`

### Repository
- [ ] `BudgetRepository`:
  - [ ] `getAllBudgets() → List<Budget>`
  - [ ] `getActiveBudgets() → List<Budget>` — current month + folder/category
  - [ ] `getBudgetById(String id) → Budget?`
  - [ ] `createBudget(Budget)`
  - [ ] `updateBudget(Budget)`
  - [ ] `deleteBudget(String id)`
  - [ ] `getSpentForBudget(Budget) → double` — query expenses for matching scope + period

### Spent Calculation Logic
- [ ] **Monthly budget:** SUM of expenses in `year=X, month=Y`
- [ ] **Folder budget:** SUM of expenses in `folder_id=X` for current month
- [ ] **Category budget:** SUM of expenses with `category=X` for current month
- [ ] All calculations run via SQL aggregation, not in-memory

### Budget List Screen
- [ ] Grouped: Monthly / Folder / Category sections
- [ ] Each card: budget name, progress bar, spent/total, % used
- [ ] Progress bar color: green (<50%), orange (50–79%), red (≥80%)
- [ ] FAB to add budget

### Add / Edit Budget Screen
- [ ] Budget type selector
- [ ] Name (auto-filled from type selection)
- [ ] Amount input
- [ ] Type-specific fields:
  - [ ] Monthly: month/year picker (default current)
  - [ ] Folder: folder selector
  - [ ] Category: category selector
- [ ] Alert toggles: 50% / 80% / 100%
- [ ] Save → `createBudget`

### Budget Alert Logic
- [ ] After every expense addition, run `getSpentForBudget` for all affected budgets
- [ ] If threshold crossed and not already alerted this session:
  - [ ] Show in-app snackbar or banner: "Food budget 80% used"
  - [ ] Schedule local notification (Module 15)
- [ ] Track `last_alerted_threshold` in memory (not DB) to avoid repeated alerts per session

### Dashboard Widget
- [ ] Show top 3 budgets by % used
- [ ] Tap to go to Budget list

### Providers
- [ ] `budgetsProvider` — `FutureProvider<List<Budget>>`
- [ ] `budgetProgressProvider(budgetId)` — spent + percent
- [ ] `budgetAlertsProvider` — budgets over alert thresholds

---

## Acceptance Criteria
- Budget spent amount matches actual expenses for scope and period
- Progress bars accurately reflect percentage used
- Alert fires exactly once per threshold crossing per session
- Multiple budget types coexist without conflict
