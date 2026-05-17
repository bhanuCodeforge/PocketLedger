# Task 12 — Dashboard (Module 12)

## Goal
Home screen giving an at-a-glance financial snapshot: today's spending, monthly totals, wallet balances, active loans, budget status.

---

## Tasks

### Layout Structure
- [x] Sticky header: greeting ("Hi [name]!"), current date, settings icon
- [x] Scrollable widget grid:
  1. Today Expense card
  2. Month Expense card
  3. Total Income (month) card
  4. Wallet balance summary (horizontal scroll)
  5. Pending loans card
  6. Group dues card
  7. Budget alerts section
  8. Recent transactions list (last 10)

### Widget: Today Expense
- [x] Total expenses for today (local timezone)
- [x] Trend indicator vs yesterday (↑↓ %)
- [x] Tap → Expense list filtered to today

### Widget: Month Expense
- [x] Total expenses for current calendar month
- [x] Progress vs last month
- [x] Tap → Expense list filtered to current month

### Widget: Total Income (Month)
- [x] Total income for current month
- [x] Tap → Income list filtered to current month

### Widget: Wallet Balance Carousel
- [x] Horizontal scroll cards per wallet
- [x] Each card: wallet name, type icon, balance, color
- [x] Tap → Wallet detail (transaction list for that wallet)
- [x] Last card: "Total Balance" (sum of all active wallets)

### Widget: Pending Loans
- [x] Count of active + overdue loans
- [x] Net amount outstanding (given − taken)
- [x] Tap → Loan list

### Widget: Group Dues
- [x] Count of groups where user owes or is owed
- [x] Your net balance across all groups
- [x] Tap → Group list

### Widget: Budget Alerts
- [x] Show budgets ≥ 50% used as progress chips
- [x] Color-coded by severity
- [x] Tap chip → Budget detail

### Widget: Recent Transactions
- [x] Last 10 transactions (expenses + income mixed, sorted by date desc)
- [x] Each row: icon, description, amount (red/green), date
- [x] "See All" link → Combined transaction list

### FAB (Floating Action Button)
- [x] Speed dial FAB:
  - [x] Add Expense (primary)
  - [x] Add Income
  - [x] Add Loan
  - [x] Transfer (wallet to wallet)

### Pull-to-Refresh
- [x] Refresh all dashboard providers on pull
- [x] Show shimmer skeletons during loading

### Providers (all data from existing module providers)
- [x] `dashboardProvider` — aggregate `FutureProvider` that waits on:
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
