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
- [x] `LoanCalculator.simpleInterest(principal, rate, years) → double`
  - Formula: `SI = (P × R × T) / 100`
- [x] `LoanCalculator.compoundAmount(principal, rate, n, years) → double`
  - Formula: `A = P × (1 + r/n)^(n×t)`
- [x] `LoanCalculator.totalDue(Loan, List<LoanPayment>) → double`
  - Total due = principal + accrued interest − payments made
- [x] `LoanCalculator.daysSince(DateTime start) → double` — for T computation
- [x] Unit tests for all formulas

### Model
- [x] `Loan` model with `fromMap` / `toMap`
- [x] `LoanPayment` model with `fromMap` / `toMap`
- [x] `LoanType` enum: given, taken
- [x] `InterestType` enum: simple, compound

### Repository
- [x] `LoanRepository`:
  - [x] `getAllLoans() → List<Loan>`
  - [x] `getActiveLoans() → List<Loan>`
  - [x] `getOverdueLoans() → List<Loan>`
  - [x] `getLoanById(String id) → Loan?`
  - [x] `getLoansByContact(String contactId) → List<Loan>`
  - [x] `createLoan(Loan)`
  - [x] `updateLoan(Loan)`
  - [x] `markSettled(String id)`
  - [x] `getPaymentsForLoan(String loanId) → List<LoanPayment>`
  - [x] `addPayment(LoanPayment)`
  - [x] `deletePayment(String paymentId)`

### Loan List Screen
- [x] Tabs: Given | Taken | Overdue | Settled
- [x] Each card: contact name, principal, total due (with interest), due date, status badge
- [x] Color code: overdue = red, due soon (≤7 days) = orange, settled = grey
- [x] FAB to add loan

### Add / Edit Loan Screen
- [x] Type toggle: Money Given / Money Taken
- [x] Contact selector (from contacts table)
- [x] Principal amount
- [x] Interest rate (%) — optional, default 0
- [x] Interest type: Simple / Compound
- [x] Compound frequency: Monthly / Quarterly / Half-yearly / Yearly
- [x] Start date (default today)
- [x] Due date picker (optional)
- [x] Wallet selector
- [x] Notes
- [x] Save → validate → `createLoan`

### Loan Detail Screen
- [x] Summary: principal, interest accrued, amount paid, amount due
- [x] Payment history list (date, amount, wallet)
- [x] "Add Payment" button
- [x] Interest table (monthly breakdown for next 12 months)
- [x] "Mark as Settled" button (only when total paid ≥ total due)
- [x] Edit / Delete loan

### Add Payment Screen
- [x] Amount (≤ remaining due)
- [x] Date
- [x] Wallet selector
- [x] Notes
- [x] Save → `addPayment`; optionally auto-settle if fully paid

### Overdue Detection
- [x] On app launch, run query: loans where `due_date < today AND status = 'active'`
- [x] Update `status = 'overdue'` for those loans
- [x] Schedule local notification (Module 15) for loans due in 7/3/1 days

### Providers
- [x] `loansProvider` — `FutureProvider<List<Loan>>`
- [x] `pendingLoansProvider` — active + overdue count for dashboard
- [x] `loanDetailProvider(loanId)` — payments + computed amounts

---

## Edge Cases & Error Handling

### Interest Calculation
- [x] Zero interest rate → `totalDue = principal - payments` (no interest added)
- [x] Very long duration (>10 years compound) → no overflow; use `double` throughout, document precision limit
- [x] Due date before start date → validation error on form: "Due date must be after start date"
- [x] Elapsed time = 0 days → SI = 0, compound = principal (correct)
- [x] Partial payment > remaining due → reject with error: "Payment exceeds remaining balance"

### Loan Lifecycle
- [x] Settled loan: prevent adding more payments; show "This loan is settled" badge
- [x] Reopening a settled loan (e.g., partial reversal): allow only via explicit "Reopen" action with confirmation
- [x] Deleting a loan with payments → cascade delete all `loan_payments` (FK ON DELETE CASCADE already defined)
- [x] Contact deleted while loan active → loans retain `contact_id`; show "[Deleted contact]" as name

### Overdue Detection
- [x] Run overdue check both at launch AND when app resumes from background
- [x] Loans without a due date are never marked overdue (status stays `active`)
- [x] Overdue loans that get a payment should NOT auto-clear overdue status — only "Mark Settled" resolves it

### Floating Point Precision
- [x] All currency amounts stored as `REAL` (8-byte float, ~15 significant digits)
- [x] Round all displayed amounts to 2 decimal places using `toStringAsFixed(2)` — never show `₹99.999999`
- [x] When comparing `totalPaid >= totalDue`, use tolerance: `(totalPaid - totalDue).abs() < 0.01`

---

## UI Micro-Interactions
- [x] Loan card: due date shown as relative ("Due in 3 days" / "Overdue by 2 days") using `intl` `RelativeDateFormat`
- [x] Overdue loans: pulsing red border animation on card
- [x] Interest accrual: live-updating counter on Loan Detail screen (updates every second via `Timer.periodic`)
- [x] "Mark as Settled" button: only enabled when `totalPaid >= totalDue × 0.99` (within 1%)
- [x] Payment added: green flash animation on "Amount Paid" total before updating

---

## Acceptance Criteria
- Simple and compound interest formulas produce correct results (verified with unit tests)
- Partial payments reduce outstanding balance correctly
- Overdue loans are flagged on app launch
- Settling a loan updates status and removes from active list
- Payment exceeding balance is rejected at the form level
