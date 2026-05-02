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
- [ ] `Expense` model with `fromMap` / `toMap`
- [ ] `ExpenseCategory` enum: food, grocery, fuel, rent, medical, shopping, travel, entertainment, education, utilities, salary_given, other
- [ ] `PaymentMode` enum: cash, card, upi, bankTransfer, other
- [ ] `tags` field: `List<Tag>`
- [ ] `attachments` field: `List<Attachment>`

### Repository
- [ ] `ExpenseRepository`:
  - [ ] `getExpenses({DateTime? from, DateTime? to, String? folderId, String? walletId, String? category}) → List<Expense>`
  - [ ] `getExpenseById(String id) → Expense?`
  - [ ] `getExpensesForToday() → List<Expense>`
  - [ ] `getExpensesForMonth(int year, int month) → List<Expense>`
  - [ ] `getTotalExpenseForPeriod(DateTime from, DateTime to) → double`
  - [ ] `createExpense(Expense, List<String> tagNames, List<File> attachments)`
  - [ ] `updateExpense(Expense, List<String> tagNames)`
  - [ ] `deleteExpense(String id)`
  - [ ] `duplicateExpense(String id) → Expense` — copies with today's date

### Expense List Screen
- [ ] Grouped by date (Today, Yesterday, older by day)
- [ ] Each row: category icon, description, folder name, amount (red), wallet name
- [ ] Filter bar: date range, folder, wallet, category
- [ ] Sort: newest first (default), oldest, amount high/low
- [ ] Infinite scroll with pagination (50 per page)
- [ ] Swipe left → Delete (with confirm dialog)
- [ ] Swipe right → Duplicate

### Add / Edit Expense Screen
- [ ] Amount field — large numeric input, required
- [ ] Category selector — icon grid
- [ ] Description — text field
- [ ] Date & time picker (default: now)
- [ ] Wallet selector — dropdown of active wallets
- [ ] Folder selector — hierarchical picker
- [ ] Payment mode selector
- [ ] Contact linker (optional)
- [ ] Tags input — chip input, auto-complete from existing tags
- [ ] Notes — multiline text
- [ ] Attachment section:
  - [ ] Pick from gallery / camera
  - [ ] Show thumbnail previews
  - [ ] Delete attachment
- [ ] Save button → validate → `createExpense`

### Expense Detail Screen
- [ ] Full detail view (read-only)
- [ ] Edit and Delete action buttons
- [ ] Attachment viewer (full-screen on tap)

### Tag Management
- [ ] Tags are created on-the-fly when user types new tag name
- [ ] Auto-complete suggests from existing `tags` table
- [ ] Tag cloud view in search / reports (future)

### Attachment Handling
- [ ] Copy picked image to app documents directory under `attachments/<entity_id>/`
- [ ] Store local path in `attachments` table
- [ ] Delete file from filesystem when attachment record deleted

### Providers
- [ ] `expensesProvider` — filtered `FutureProvider<List<Expense>>`
- [ ] `todayExpenseProvider` — `FutureProvider<double>`
- [ ] `monthExpenseProvider` — `FutureProvider<double>`

---

## Edge Cases & Error Handling

### Amount Validation
- [ ] Amount field must reject: negative numbers, zero, non-numeric input, amounts > 99,99,999 (guard against typos)
- [ ] Decimal separator: accept both `.` and `,` (localize); normalize to `.` before saving
- [ ] Paste from clipboard: strip currency symbols before parsing (`₹`, `$`, `,`)

### Date Edge Cases
- [ ] Future dates allowed (budgeting ahead) but show warning: "This expense is dated in the future"
- [ ] Dates more than 10 years in the past show warning
- [ ] Timezone handling: store date as ISO 8601 with offset; display in user's local timezone

### Wallet Edge Cases
- [ ] If last wallet is archived mid-session → expense form shows error "No active wallet available" + link to create wallet
- [ ] Wallet balance going negative: allowed (e.g., credit card), but show visual indicator (red balance)

### Attachment Edge Cases
- [ ] Image > 10 MB: offer to compress before saving (use `flutter_image_compress`)
- [ ] Storage full: catch `FileSystemException`, show "Storage full — cannot save attachment"
- [ ] App killed during image copy → orphan cleanup on next launch handles temp files
- [ ] HEIC format (iOS): convert to JPEG before storing (compatibility with Android restore)

### Tag Edge Cases
- [ ] Tags are case-insensitive: "Food" and "food" are the same tag (store lowercase, display as-entered)
- [ ] Tag name max length: 30 characters
- [ ] Maximum 10 tags per expense (UX limit)
- [ ] Deleting a tag from the `tags` table: cascade via `entity_tags` ON DELETE CASCADE

### Duplicate Expense
- [ ] Duplicated expense gets a new UUID and `created_at`/`updated_at` = now
- [ ] Show snackbar: "Expense duplicated" with "Edit" action button

### Delete Expense
- [ ] Soft confirmation: swipe-to-delete shows undo snackbar (3 second window)
- [ ] After 3 seconds: actual DB delete + file system delete of attachments
- [ ] If expense is linked to a group transaction → warn: "This expense is part of a group split. Deleting it won't update the group."

### Concurrency
- [ ] Two rapid saves (double-tap): debounce save button (disable on first tap, re-enable after DB write resolves)

---

## UI Micro-Interactions
- [ ] Amount field: large font (32 sp), numeric keyboard auto-shown, cursor at end
- [ ] Category chips: horizontal scroll with haptic on selection
- [ ] Saving: save button shows `CircularProgressIndicator` while DB write in progress
- [ ] Success: brief green checkmark animation before popping screen
- [ ] Swipe-to-delete: red background with trash icon revealed behind row
- [ ] Tag input: pressing comma or space creates a tag chip inline
- [ ] Attachment thumbnail: long-press reveals "Delete" overlay with red tint
- [ ] Date field: bottom sheet date picker (not dialog) for better reachability

---

## Acceptance Criteria
- Expense with all fields saves and displays correctly
- Filtering and sorting work independently
- Attachment images persist across sessions
- Delete removes DB record and local file
- Duplicate creates a new expense with today's date
