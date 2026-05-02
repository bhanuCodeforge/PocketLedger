# Task 23 — AI Insights (Module 23 / v3.0)

## Goal
On-device rule-based engine that analyzes spending patterns and surfaces actionable insights. No cloud API, no network calls, full privacy.

---

## Tasks

### Insight Types

| Type | Example |
|------|---------|
| `spending_spike` | "Food spend is 40% higher than last month" |
| `budget_risk` | "At this rate you'll exceed Grocery budget in 5 days" |
| `saving_opportunity` | "You've saved ₹3,200 more than last month — keep it up!" |
| `anomaly` | "Unusual large expense of ₹8,000 on Entertainment" |
| `loan_reminder` | "₹5,000 loan due to Rahul in 3 days" |
| `top_category` | "Food is your highest spend category (32% of expenses)" |
| `net_trend` | "Your net savings trend is improving over 3 months" |
| `idle_wallet` | "Cash wallet hasn't had activity in 30 days" |

### Insight Engine
- [ ] `InsightEngine.run(InsightContext ctx) → List<Insight>`
  - Called after app launch and after each significant write (expense, income, loan)
  - Runs all insight rules in sequence
  - Deduplicates against existing `ai_insights` table
  - Inserts new, non-expired insights

### Insight Rules (each as a separate class implementing `InsightRule`)

#### Rule 1: Spending Spike Detection
```
Compare current month total per category vs previous month total per category.
If current > previous × 1.3 (30% spike) → generate spending_spike insight.
```
- [ ] Implement for top 5 categories
- [ ] Threshold configurable (default: 30%)

#### Rule 2: Budget Burn Rate
```
Days elapsed in month / total days in month = elapsed fraction.
Budget spent / budget total = spent fraction.
If spent_fraction > elapsed_fraction × 1.2 → "at risk of exceeding budget".
Estimate days to depletion: remaining_budget / daily_avg_spend.
```
- [ ] Run for all active budgets
- [ ] Only trigger if at least 7 days into the month

#### Rule 3: Savings Positive Trend
```
Net savings = income - expense per month.
If current_month_net > last_month_net → saving_opportunity insight.
Only trigger if saving ≥ 5% improvement.
```

#### Rule 4: Large Expense Anomaly
```
For each expense: if amount > category_90th_percentile × 2 → anomaly.
90th percentile computed from last 3 months of data for that category.
```
- [ ] Only flag if category has ≥ 10 historical entries (avoid false positives on sparse data)

#### Rule 5: Top Category
```
At month end (after day 25), surface top category by spend % of total.
Only show if top category > 30% of total.
```

#### Rule 6: Idle Wallet
```
If a wallet has no transactions in 30 days and balance > 0 → idle_wallet insight.
```

#### Rule 7: Net Savings Trend (3-month)
```
Compute net savings for last 3 complete months.
If each month > previous month → positive trend.
If each month < previous → negative trend (warn).
```

### Insight Model
```dart
class Insight {
  final String id;
  final InsightType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;  // supporting numbers
  final DateTime validUntil;
  bool isRead;
}
```

### Insight Context
```dart
class InsightContext {
  final List<Expense> last3MonthsExpenses;
  final List<Income> last3MonthsIncome;
  final List<Wallet> wallets;
  final List<Budget> activeBudgets;
  final List<Loan> activeLoans;
  final DateTime now;
}
```

### Insights Screen
- [ ] List of active (non-expired) insights, newest first
- [ ] Each card:
  - [ ] Icon (color-coded by type: blue=info, orange=warning, red=alert, green=positive)
  - [ ] Title (bold)
  - [ ] Body text
  - [ ] Supporting data chip (e.g., "₹3,450 / ₹5,000")
  - [ ] "View Details" link → navigates to relevant screen (budget, category report, etc.)
  - [ ] Dismiss (X) button → marks `is_read = 1`
- [ ] "Refresh Insights" pull-to-refresh
- [ ] Empty state: "All looks good! No insights right now."

### Dashboard Integration
- [ ] Show top 2 unread insights as cards on Dashboard
- [ ] Insights bell icon in AppBar with unread badge count
- [ ] Tap bell → `/insights`

### Insight Expiry
- [ ] `spending_spike` → valid until end of current month
- [ ] `budget_risk` → valid until budget period ends
- [ ] `anomaly` → valid for 7 days
- [ ] `saving_opportunity` → valid for 14 days
- [ ] On app launch: delete expired insights (`valid_until < now`)

### Performance
- [ ] `InsightEngine.run()` runs in an `Isolate` to avoid blocking UI
- [ ] Context data pre-fetched from DB before spawning isolate
- [ ] Total run time target: < 500 ms on 3 months of data

---

## Acceptance Criteria
- All 7 rules produce correct insights when conditions are met
- Insights do not repeat within their validity period
- No network calls made (verified by disabling WiFi during testing)
- Engine runs in < 500 ms on 12,000 records
- Expired insights are cleaned up on launch
