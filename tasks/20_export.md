# Task 20 — Export (Module 20)

## Goal
Export transaction data as PDF, CSV, or Excel for any date range and scope.

---

## Tasks

### Packages
- [x] `pdf` — PDF generation
- [x] `excel` — Excel `.xlsx` generation
- [x] `csv` — CSV string builder
- [x] `share_plus` — Share exported file
- [x] `path_provider` — Temp file storage for export

### Export Service
- [x] `ExportService`:
  - [x] `exportPdf(ExportOptions) → File`
  - [x] `exportCsv(ExportOptions) → File`
  - [x] `exportExcel(ExportOptions) → File`
  - [x] `shareFile(File)` — opens OS share sheet

### Export Options Model
```dart
class ExportOptions {
  final ExportFormat format;    // pdf | csv | excel
  final ExportScope scope;      // all | expenses | income | loans | summary
  final DateTime from;
  final DateTime to;
  final String? folderId;       // optional folder filter
  final String? walletId;       // optional wallet filter
  final bool includeAttachments; // PDF only
}
```

### Export Screen / Bottom Sheet
- [x] Format selector: PDF / CSV / Excel (icon buttons)
- [x] Scope selector: All Transactions / Expenses Only / Income Only / Loans / Summary Report
- [x] Date range picker: This Month / Last Month / This Year / Custom
- [x] Folder filter (optional)
- [x] Wallet filter (optional)
- [x] "Include attachments" toggle (PDF only)
- [x] "Export" button → shows progress → share sheet

---

### PDF Export Layout
- [x] Cover page:
  - App name + logo
  - Export period
  - Generated date
  - User name (if set)
- [x] Summary table:
  - Total income, total expense, net savings, number of transactions
- [x] Transactions table (per page, 25 rows):
  - Columns: Date | Category | Description | Folder | Wallet | Amount
  - Alternating row colors
  - Red for expenses, green for income
- [x] Category breakdown pie chart (rendered as static image using `fl_chart` → image bytes)
- [x] Loan summary table (if scope includes loans)
- [x] Footer: page number, app name
- [x] Font: use `pw.Font.helvetica()` (built into `pdf` package, no external font needed)

### CSV Export Layout
```
Date,Type,Category,Description,Folder,Wallet,Amount,Notes,Tags
2026-04-01,Expense,Food,Lunch at Cafe,Personal > Food,Cash,-250.00,Quick lunch,"food,cafe"
2026-04-01,Income,Salary,Monthly salary,,Bank Account,85000.00,,
```
- [x] Header row always first
- [x] Amounts: negative for expense, positive for income
- [x] Dates in `YYYY-MM-DD` format
- [x] Tags comma-separated within quotes

### Excel Export Layout
- [x] Sheet 1: **Transactions** — same columns as CSV, with auto-fit columns
- [x] Sheet 2: **Income** — income-only rows
- [x] Sheet 3: **Expenses** — expense-only rows
- [x] Sheet 4: **Summary** — pivot-style: category totals, wallet totals, monthly totals
- [x] Sheet 5: **Loans** — loan list with principal, interest, paid, remaining
- [x] Bold header row, freeze top row on each sheet
- [x] Currency columns formatted as number with 2 decimal places

### File Naming
- [x] `PocketLedger_Export_{from}_{to}.pdf`
- [x] `PocketLedger_Export_{from}_{to}.csv`
- [x] `PocketLedger_Export_{from}_{to}.xlsx`
- [x] Save to `{app_documents_dir}/exports/` then share

### Export from Reports
- [x] Reports screen (Module 13) has an "Export" button that pre-fills current period/scope

### Export from Settings
- [x] Settings > Export section triggers this screen

### Providers
- [x] `exportOptionsProvider` — `StateNotifierProvider<ExportOptions>`
- [x] `exportProgressProvider` — `StateProvider<double>` (0.0–1.0 for progress bar)

---

## Acceptance Criteria
- PDF renders correctly with all sections and is shareable
- CSV opens correctly in Google Sheets / Excel with proper encoding (UTF-8 BOM for Excel compatibility)
- Excel file has all 5 sheets with formatted data
- Large exports (5,000+ rows) complete without memory errors
- File is saved to documents dir and immediately shareable via OS share sheet
