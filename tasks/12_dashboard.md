# Task 12 — Dashboard (Module 12)

## Goal
Home screen giving an at-a-glance financial snapshot: today's spending, monthly totals, wallet balances, active loans, budget status.

---

## Tasks

### Layout Structure
- [ ] Sticky header: greeting ("Hi [name]!"), current date, settings icon
- [ ] Scrollable widget grid:
  1. Today Expense card
  2. Month Expense card
  3. Total Income (month) card
  4. Wallet balance summary (horizontal scroll)
  5. Pending loans card
  6. Group dues card
  7. Budget alerts section
  8. Recent transactions list (last 10)

### Widget: Today Expense
- [ ] Total expenses for today (local timezone)
- [ ] Trend indicator vs yesterday (↑↓ %)
- [ ] Tap → Expense list filtered to today

### Widget: Month Expense
- [ ] Total expenses for current calendar month
- [ ] Progress vs last month
- [ ] Tap → Expense list filtered to current month

### Widget: Total Income (Month)
- [ ] Total income for current month
- [ ] Tap → Income list filtered to current month

### Widget: Wallet Balance Carousel
- [ ] Horizontal scroll cards per wallet
- [ ] Each card: wallet name, type icon, balance, color
- [ ] Tap → Wallet detail (transaction list for that wallet)
- [ ] Last card: "Total Balance" (sum of all active wallets)

### Widget: Pending Loans
- [ ] Count of active + overdue loans
- [ ] Net amount outstanding (given − taken)
- [ ] Tap → Loan list

### Widget: Group Dues
- [ ] Count of groups where user owes or is owed
- [ ] Your net balance across all groups
- [ ] Tap → Group list

### Widget: Budget Alerts
- [ ] Show budgets ≥ 50% used as progress chips
- [ ] Color-coded by severity
- [ ] Tap chip → Budget detail

### Widget: Recent Transactions
- [ ] Last 10 transactions (expenses + income mixed, sorted by date desc)
- [ ] Each row: icon, description, amount (red/green), date
- [ ] "See All" link → Combined transaction list

### FAB (Floating Action Button)
- [ ] Speed dial FAB:
  - [ ] Add Expense (primary)
  - [ ] Add Income
  - [ ] Add Loan
  - [ ] Transfer (wallet to wallet)

### Pull-to-Refresh
- [ ] Refresh all dashboard providers on pull
- [ ] Show shimmer skeletons during loading

### Providers (all data from existing module providers)
- [ ] `dashboardProvider` — aggregate `FutureProvider` that waits on:
  - `todayExpenseProvider`
  - `monthExpenseProvider`
  - `monthIncomeProvider`
  - `walletsProvider`
  - `pendingLoansProvider`
  - `groupDuesProvider`
  - `budgetAlertsProvider`
  - `recentTransactionsProvider`

---

## Acceptance Criteria
- Dashboard loads in <500 ms after DB open on a mid-range device
- All numbers match their respective module list screens
- Shimmer shown while data loads; no layout shift after load
- FAB speed dial opens smoothly and navigates to correct add screens
