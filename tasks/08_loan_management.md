# Task 08 — Loan Management (Module 8)

## Goal
Track money lent and borrowed with interest calculations, partial payments, and due dates.

---

## Database Tables
```sql
CREATE TABLE loans (
  id              TEXT PRIMARY KEY,
  contact_id      TEXT NOT NULL,
  type            TEXT NOT NULL,       -- given | taken
  principal       REAL NOT NULL,
  interest_rate   REAL DEFAULT 0.0,   -- annual %
  interest_type   TEXT DEFAULT 'simple',  -- simple | compound
  compound_freq   INTEGER DEFAULT 12, -- times per year (monthly=12, quarterly=4)
  start_date      TEXT NOT NULL,
  due_date        TEXT,
  status          TEXT DEFAULT 'active',  -- active | settled | overdue
  notes           TEXT,
  wallet_id       TEXT,
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL,
  FOREIGN KEY (contact_id) REFERENCES contacts(id),
  FOREIGN KEY (wallet_id) REFERENCES wallets(id)
);

CREATE TABLE loan_payments (
  id          TEXT PRIMARY KEY,
  loan_id     TEXT NOT NULL,
  amount      REAL NOT NULL,
  date        TEXT NOT NULL,
  notes       TEXT,
  wallet_id   TEXT,
  created_at  TEXT NOT NULL,
  FOREIGN KEY (loan_id) REFERENCES loans(id) ON DELETE CASCADE,
  FOREIGN KEY (wallet_id) REFERENCES wallets(id)
);
```

---

## Tasks

### Interest Calculation Utilities
- [ ] `LoanCalculator.simpleInterest(principal, rate, years) → double`
  - Formula: `SI = (P × R × T) / 100`
- [ ] `LoanCalculator.compoundAmount(principal, rate, n, years) → double`
  - Formula: `A = P × (1 + r/n)^(n×t)`
- [ ] `LoanCalculator.totalDue(Loan, List<LoanPayment>) → double`
  - Total due = principal + accrued interest − payments made
- [ ] `LoanCalculator.daysSince(DateTime start) → double` — for T computation
- [ ] Unit tests for all formulas

### Model
- [ ] `Loan` model with `fromMap` / `toMap`
- [ ] `LoanPayment` model with `fromMap` / `toMap`
- [ ] `LoanType` enum: given, taken
- [ ] `InterestType` enum: simple, compound

### Repository
- [ ] `LoanRepository`:
  - [ ] `getAllLoans() → List<Loan>`
  - [ ] `getActiveLoans() → List<Loan>`
  - [ ] `getOverdueLoans() → List<Loan>`
  - [ ] `getLoanById(String id) → Loan?`
  - [ ] `getLoansByContact(String contactId) → List<Loan>`
  - [ ] `createLoan(Loan)`
  - [ ] `updateLoan(Loan)`
  - [ ] `markSettled(String id)`
  - [ ] `getPaymentsForLoan(String loanId) → List<LoanPayment>`
  - [ ] `addPayment(LoanPayment)`
  - [ ] `deletePayment(String paymentId)`

### Loan List Screen
- [ ] Tabs: Given | Taken | Overdue | Settled
- [ ] Each card: contact name, principal, total due (with interest), due date, status badge
- [ ] Color code: overdue = red, due soon (≤7 days) = orange, settled = grey
- [ ] FAB to add loan

### Add / Edit Loan Screen
- [ ] Type toggle: Money Given / Money Taken
- [ ] Contact selector (from contacts table)
- [ ] Principal amount
- [ ] Interest rate (%) — optional, default 0
- [ ] Interest type: Simple / Compound
- [ ] Compound frequency: Monthly / Quarterly / Half-yearly / Yearly
- [ ] Start date (default today)
- [ ] Due date picker (optional)
- [ ] Wallet selector
- [ ] Notes
- [ ] Save → validate → `createLoan`

### Loan Detail Screen
- [ ] Summary: principal, interest accrued, amount paid, amount due
- [ ] Payment history list (date, amount, wallet)
- [ ] "Add Payment" button
- [ ] Interest table (monthly breakdown for next 12 months)
- [ ] "Mark as Settled" button (only when total paid ≥ total due)
- [ ] Edit / Delete loan

### Add Payment Screen
- [ ] Amount (≤ remaining due)
- [ ] Date
- [ ] Wallet selector
- [ ] Notes
- [ ] Save → `addPayment`; optionally auto-settle if fully paid

### Overdue Detection
- [ ] On app launch, run query: loans where `due_date < today AND status = 'active'`
- [ ] Update `status = 'overdue'` for those loans
- [ ] Schedule local notification (Module 15) for loans due in 7/3/1 days

### Providers
- [ ] `loansProvider` — `FutureProvider<List<Loan>>`
- [ ] `pendingLoansProvider` — active + overdue count for dashboard
- [ ] `loanDetailProvider(loanId)` — payments + computed amounts

---

## Edge Cases & Error Handling

### Interest Calculation
- [ ] Zero interest rate → `totalDue = principal - payments` (no interest added)
- [ ] Very long duration (>10 years compound) → no overflow; use `double` throughout, document precision limit
- [ ] Due date before start date → validation error on form: "Due date must be after start date"
- [ ] Elapsed time = 0 days → SI = 0, compound = principal (correct)
- [ ] Partial payment > remaining due → reject with error: "Payment exceeds remaining balance"

### Loan Lifecycle
- [ ] Settled loan: prevent adding more payments; show "This loan is settled" badge
- [ ] Reopening a settled loan (e.g., partial reversal): allow only via explicit "Reopen" action with confirmation
- [ ] Deleting a loan with payments → cascade delete all `loan_payments` (FK ON DELETE CASCADE already defined)
- [ ] Contact deleted while loan active → loans retain `contact_id`; show "[Deleted contact]" as name

### Overdue Detection
- [ ] Run overdue check both at launch AND when app resumes from background
- [ ] Loans without a due date are never marked overdue (status stays `active`)
- [ ] Overdue loans that get a payment should NOT auto-clear overdue status — only "Mark Settled" resolves it

### Floating Point Precision
- [ ] All currency amounts stored as `REAL` (8-byte float, ~15 significant digits)
- [ ] Round all displayed amounts to 2 decimal places using `toStringAsFixed(2)` — never show `₹99.999999`
- [ ] When comparing `totalPaid >= totalDue`, use tolerance: `(totalPaid - totalDue).abs() < 0.01`

---

## UI Micro-Interactions
- [ ] Loan card: due date shown as relative ("Due in 3 days" / "Overdue by 2 days") using `intl` `RelativeDateFormat`
- [ ] Overdue loans: pulsing red border animation on card
- [ ] Interest accrual: live-updating counter on Loan Detail screen (updates every second via `Timer.periodic`)
- [ ] "Mark as Settled" button: only enabled when `totalPaid >= totalDue × 0.99` (within 1%)
- [ ] Payment added: green flash animation on "Amount Paid" total before updating

---

## Acceptance Criteria
- Simple and compound interest formulas produce correct results (verified with unit tests)
- Partial payments reduce outstanding balance correctly
- Overdue loans are flagged on app launch
- Settling a loan updates status and removes from active list
- Payment exceeding balance is rejected at the form level
