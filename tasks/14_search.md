# Task 14 — Search (Module 14)

## Goal
Global full-text search across all transactions, contacts, folders, and notes.

---

## Tasks

### Search Scope
Search across:
- [x] Expenses (description, notes, amount, category, tag)
- [x] Income (description, notes, amount, category)
- [x] Loans (notes, contact name, amount)
- [x] Contacts (name, phone, email)
- [x] Folders (name)

### Search Screen
- [x] Search bar auto-focused on open
- [x] Recent searches list (stored in memory, max 10)
- [x] Clear recent searches button
- [x] Results appear live as user types (≥2 characters)
- [x] Results grouped by type: Expenses | Income | Loans | Contacts | Folders
- [x] "No results" empty state with icon

### Search Filters
- [x] Filter chips below search bar: All / Expenses / Income / Loans / Contacts
- [x] Date range filter (tap calendar icon)
- [x] Amount range filter (min, max)

### Result Items
- [x] **Expense result:** category icon, description, amount (red), date, folder
- [x] **Income result:** category icon, description, amount (green), date
- [x] **Loan result:** contact avatar, principal, type (given/taken), status
- [x] **Contact result:** avatar, name, outstanding balance
- [x] **Folder result:** folder icon (colored), name, parent folder
- [x] Tapping any result navigates to its detail screen

### Search Query Implementation
```sql
-- Expense search
SELECT * FROM expenses
WHERE description LIKE ? OR notes LIKE ? OR amount = ?
ORDER BY date DESC LIMIT 50;

-- Join tags
SELECT e.* FROM expenses e
JOIN expense_tags et ON et.expense_id = e.id
JOIN tags t ON t.id = et.tag_id
WHERE t.name LIKE ?;
```
- [x] Implement debounced search (300 ms after last keystroke)
- [x] Run all sub-queries in parallel using `Future.wait`
- [x] Merge and sort results by relevance (exact match first, then partial)

### Amount Search
- [x] If query is a valid number, also search by exact amount match
- [x] e.g., searching "500" shows expenses/income with amount = 500

### Person Search
- [x] Searching a name finds:
  - Contacts with that name
  - Expenses linked to that contact
  - Loans linked to that contact

### Providers
- [x] `searchQueryProvider` — `StateProvider<String>`
- [x] `searchResultsProvider` — `FutureProvider<SearchResults>` (debounced)
- [x] `SearchResults` model: `expenses, income, loans, contacts, folders`

---

## Acceptance Criteria
- Results appear within 300 ms of typing (on device with 10,000+ records)
- Amount search finds exact matches
- Tapping any result opens the correct detail screen
- Recent searches persist within the session
