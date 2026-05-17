# Task 13 — Reports & Analytics (Module 13)

## Goal
Visualize spending patterns with interactive charts across daily, weekly, monthly, and yearly views.

---

## Tasks

### Report Periods
- [x] Daily view — bar chart, expenses per hour of day
- [x] Weekly view — bar chart, Mon–Sun
- [x] Monthly view — bar chart, day 1–31
- [x] Yearly view — bar chart, Jan–Dec

### Reports Screen Layout
- [x] Period selector tabs: Day / Week / Month / Year
- [x] Date navigator: < [Period Label] > (navigate forward/backward)
- [x] Chart area (top 40% of screen)
- [x] Summary cards below chart
- [x] List of top categories / wallets for period

### Chart: Category Spending Breakdown
- [x] Pie / donut chart — expense by category for selected period
- [x] Legend with amount and % per slice
- [x] Tap slice → filter transaction list to that category
- [x] Package: `fl_chart` `PieChart`

### Chart: Wallet Usage
- [x] Stacked bar or grouped bar per wallet
- [x] Shows expense drawn from each wallet per period
- [x] Package: `fl_chart` `BarChart`

### Chart: Cash Flow
- [x] Dual-line chart: income (green) vs expense (red) over time
- [x] Net balance line (blue) = cumulative income − expense
- [x] Package: `fl_chart` `LineChart`

### Chart: Loan Profit (Interest Earned)
- [x] Bar chart per active loan — principal vs interest earned
- [x] Only shown for "given" loans with interest > 0

### Summary Cards (per selected period)
- [x] Total income
- [x] Total expense
- [x] Net savings (income − expense)
- [x] Largest single expense
- [x] Highest spending category

### Transaction Drill-Down
- [x] Tapping a chart element opens filtered transaction list
- [x] Filter preserved: period + entity (category/wallet/folder)

### Data Queries
- [x] `ReportRepository`:
  - [x] `getExpenseByCategory(from, to) → Map<String, double>`
  - [x] `getExpenseByWallet(from, to) → Map<String, double>`
  - [x] `getExpenseByDay(from, to) → Map<DateTime, double>`
  - [x] `getIncomeByDay(from, to) → Map<DateTime, double>`
  - [x] `getNetCashFlow(from, to) → List<{date, income, expense}>`
  - [x] `getTopFolders(from, to, limit: 5) → List<{folder, amount}>`

### Export from Reports
- [x] "Export" button on report screen → triggers Module 20 export flow for selected period

### Providers
- [x] `reportPeriodProvider` — `StateProvider<ReportPeriod>`
- [x] `categoryBreakdownProvider` — `FutureProvider<Map<String, double>>`
- [x] `cashFlowProvider` — `FutureProvider<List<CashFlowPoint>>`

---

## Acceptance Criteria
- Charts render correctly with real data
- Navigation between periods is smooth
- Tapping chart navigates to filtered list with correct data
- Empty state shown gracefully when no data for period
