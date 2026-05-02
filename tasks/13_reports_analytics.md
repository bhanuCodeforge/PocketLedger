# Task 13 — Reports & Analytics (Module 13)

## Goal
Visualize spending patterns with interactive charts across daily, weekly, monthly, and yearly views.

---

## Tasks

### Report Periods
- [ ] Daily view — bar chart, expenses per hour of day
- [ ] Weekly view — bar chart, Mon–Sun
- [ ] Monthly view — bar chart, day 1–31
- [ ] Yearly view — bar chart, Jan–Dec

### Reports Screen Layout
- [ ] Period selector tabs: Day / Week / Month / Year
- [ ] Date navigator: < [Period Label] > (navigate forward/backward)
- [ ] Chart area (top 40% of screen)
- [ ] Summary cards below chart
- [ ] List of top categories / wallets for period

### Chart: Category Spending Breakdown
- [ ] Pie / donut chart — expense by category for selected period
- [ ] Legend with amount and % per slice
- [ ] Tap slice → filter transaction list to that category
- [ ] Package: `fl_chart` `PieChart`

### Chart: Wallet Usage
- [ ] Stacked bar or grouped bar per wallet
- [ ] Shows expense drawn from each wallet per period
- [ ] Package: `fl_chart` `BarChart`

### Chart: Cash Flow
- [ ] Dual-line chart: income (green) vs expense (red) over time
- [ ] Net balance line (blue) = cumulative income − expense
- [ ] Package: `fl_chart` `LineChart`

### Chart: Loan Profit (Interest Earned)
- [ ] Bar chart per active loan — principal vs interest earned
- [ ] Only shown for "given" loans with interest > 0

### Summary Cards (per selected period)
- [ ] Total income
- [ ] Total expense
- [ ] Net savings (income − expense)
- [ ] Largest single expense
- [ ] Highest spending category

### Transaction Drill-Down
- [ ] Tapping a chart element opens filtered transaction list
- [ ] Filter preserved: period + entity (category/wallet/folder)

### Data Queries
- [ ] `ReportRepository`:
  - [ ] `getExpenseByCategory(from, to) → Map<String, double>`
  - [ ] `getExpenseByWallet(from, to) → Map<String, double>`
  - [ ] `getExpenseByDay(from, to) → Map<DateTime, double>`
  - [ ] `getIncomeByDay(from, to) → Map<DateTime, double>`
  - [ ] `getNetCashFlow(from, to) → List<{date, income, expense}>`
  - [ ] `getTopFolders(from, to, limit: 5) → List<{folder, amount}>`

### Export from Reports
- [ ] "Export" button on report screen → triggers Module 20 export flow for selected period

### Providers
- [ ] `reportPeriodProvider` — `StateProvider<ReportPeriod>`
- [ ] `categoryBreakdownProvider` — `FutureProvider<Map<String, double>>`
- [ ] `cashFlowProvider` — `FutureProvider<List<CashFlowPoint>>`

---

## Acceptance Criteria
- Charts render correctly with real data
- Navigation between periods is smooth
- Tapping chart navigates to filtered list with correct data
- Empty state shown gracefully when no data for period
