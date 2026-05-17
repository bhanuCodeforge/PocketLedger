# Task 06 — Expense Management (Module 6)

## Goal
Core feature: Add, edit, delete, and browse expenses with full metadata.

---

## Database Tables
```sql
CREATE TABLE expenses (
  id            TEXT PRIMARY KEY,   -- UUID
  amount        REAL NOT NULL,
  category      TEXT NOT NULL,
  description   TEXT,
  date          TEXT NOT NULL,      -- ISO 8601
  wallet_id     TEXT NOT NULL,
  folder_id     TEXT,
  payment_mode  TEXT,               -- cash | card | upi | bank_transfer | other
  contact_id    TEXT,               -- optional linked contact
  is_recurring  INTEGER DEFAULT 0,
  notes         TEXT,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  FOREIGN KEY (wallet_id) REFERENCES wallets(id),
  FOREIGN KEY (folder_id) REFERENCES folders(id),
  FOREIGN KEY (contact_id) REFERENCES contacts(id)
);

CREATE TABLE tags (
  id    TEXT PRIMARY KEY,
  name  TEXT UNIQUE NOT NULL
);

CREATE TABLE expense_tags (
  expense_id  TEXT NOT NULL,
  tag_id      TEXT NOT NULL,
  PRIMARY KEY (expense_id, tag_id),
  FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id)
);

CREATE TABLE attachments (
  id          TEXT PRIMARY KEY,
  entity_id   TEXT NOT NULL,        -- expense/income/loan id
  entity_type TEXT NOT NULL,        -- expense | income | loan
  file_path   TEXT NOT NULL,        -- local path
  file_type   TEXT,                 -- image | pdf | other
  created_at  TEXT NOT NULL
);
```

---

## Tasks

### Model
- [x] `Expense` model with `fromMap` / `toMap`
- [x] `ExpenseCategory` enum: food, grocery, fuel, rent, medical, shopping, travel, entertainment, education, utilities, salary_given, other
- [x] `PaymentMode` enum: cash, card, upi, bankTransfer, other
- [x] `tags` field: `List<Tag>`
- [x] `attachments` field: `List<Attachment>`

### Repository
- [x] `ExpenseRepository`:
  - [x] `getExpenses({DateTime? from, DateTime? to, String? folderId, String? walletId, String? category}) → List<Expense>`
  - [x] `getExpenseById(String id) → Expense?`
  - [x] `getExpensesForToday() → List<Expense>`
  - [x] `getExpensesForMonth(int year, int month) → List<Expense>`
  - [x] `getTotalExpenseForPeriod(DateTime from, DateTime to) → double`
  - [x] `createExpense(Expense, List<String> tagNames, List<File> attachments)`
  - [x] `updateExpense(Expense, List<String> tagNames)`
  - [x] `deleteExpense(String id)`
  - [x] `duplicateExpense(String id) → Expense` — copies with today's date

### Expense List Screen
- [x] Grouped by date (Today, Yesterday, older by day)
- [x] Each row: category icon, description, folder name, amount (red), wallet name
- [x] Filter bar: date range, folder, wallet, category
- [x] Sort: newest first (default), oldest, amount high/low
- [x] Infinite scroll with pagination (50 per page)
- [x] Swipe left → Delete (with confirm dialog)
- [x] Swipe right → Duplicate

### Add / Edit Expense Screen
- [x] Amount field — large numeric input, required
- [x] Category selector — icon grid
- [x] Description — text field
- [x] Date & time picker (default: now)
- [x] Wallet selector — dropdown of active wallets
- [x] Folder selector — hierarchical picker
- [x] Payment mode selector
- [x] Contact linker (optional)
- [x] Tags input — chip input, auto-complete from existing tags
- [x] Notes — multiline text
- [x] Attachment section:
  - [x] Pick from gallery / camera
  - [x] Show thumbnail previews
  - [x] Delete attachment
- [x] Save button → validate → `createExpense`

### Expense Detail Screen
- [x] Full detail view (read-only)
- [x] Edit and Delete action buttons
- [x] Attachment viewer (full-screen on tap)

### Tag Management
- [x] Tags are created on-the-fly when user types new tag name
- [x] Auto-complete suggests from existing `tags` table
- [x] Tag cloud view in search / reports (future)

### Attachment Handling
- [x] Copy picked image to app documents directory under `attachments/<entity_id>/`
- [x] Store local path in `attachments` table
- [x] Delete file from filesystem when attachment record deleted

### Providers
- [x] `expensesProvider` — filtered `FutureProvider<List<Expense>>`
- [x] `todayExpenseProvider` — `FutureProvider<double>`
- [x] `monthExpenseProvider` — `FutureProvider<double>`

---

## Edge Cases & Error Handling

### Amount Validation
- [x] Amount field must reject: negative numbers, zero, non-numeric input, amounts > 99,99,999 (guard against typos)
- [x] Decimal separator: accept both `.` and `,` (localize); normalize to `.` before saving
- [x] Paste from clipboard: strip currency symbols before parsing (`₹`, `$`, `,`)

### Date Edge Cases
- [x] Future dates allowed (budgeting ahead) but show warning: "This expense is dated in the future"
- [x] Dates more than 10 years in the past show warning
- [x] Timezone handling: store date as ISO 8601 with offset; display in user's local timezone

### Wallet Edge Cases
- [x] If last wallet is archived mid-session → expense form shows error "No active wallet available" + link to create wallet
- [x] Wallet balance going negative: allowed (e.g., credit card), but show visual indicator (red balance)

### Attachment Edge Cases
- [x] Image > 10 MB: offer to compress before saving (use `flutter_image_compress`)
- [x] Storage full: catch `FileSystemException`, show "Storage full — cannot save attachment"
- [x] App killed during image copy → orphan cleanup on next launch handles temp files
- [x] HEIC format (iOS): convert to JPEG before storing (compatibility with Android restore)

### Tag Edge Cases
- [x] Tags are case-insensitive: "Food" and "food" are the same tag (store lowercase, display as-entered)
- [x] Tag name max length: 30 characters
- [x] Maximum 10 tags per expense (UX limit)
- [x] Deleting a tag from the `tags` table: cascade via `entity_tags` ON DELETE CASCADE

### Duplicate Expense
- [x] Duplicated expense gets a new UUID and `created_at`/`updated_at` = now
- [x] Show snackbar: "Expense duplicated" with "Edit" action button

### Delete Expense
- [x] Soft confirmation: swipe-to-delete shows undo snackbar (3 second window)
- [x] After 3 seconds: actual DB delete + file system delete of attachments
- [x] If expense is linked to a group transaction → warn: "This expense is part of a group split. Deleting it won't update the group."

### Concurrency
- [x] Two rapid saves (double-tap): debounce save button (disable on first tap, re-enable after DB write resolves)

---

## UI Micro-Interactions
- [x] Amount field: large font (32 sp), numeric keyboard auto-shown, cursor at end
- [x] Category chips: horizontal scroll with haptic on selection
- [x] Saving: save button shows `CircularProgressIndicator` while DB write in progress
- [x] Success: brief green checkmark animation before popping screen
- [x] Swipe-to-delete: red background with trash icon revealed behind row
- [x] Tag input: pressing comma or space creates a tag chip inline
- [x] Attachment thumbnail: long-press reveals "Delete" overlay with red tint
- [x] Date field: bottom sheet date picker (not dialog) for better reachability

---

## Acceptance Criteria
- Expense with all fields saves and displays correctly
- Filtering and sorting work independently
- Attachment images persist across sessions
- Delete removes DB record and local file
- Duplicate creates a new expense with today's date
