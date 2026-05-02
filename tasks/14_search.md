# Task 14 — Search (Module 14)

## Goal
Global full-text search across all transactions, contacts, folders, and notes.

---

## Tasks

### Search Scope
Search across:
- [ ] Expenses (description, notes, amount, category, tag)
- [ ] Income (description, notes, amount, category)
- [ ] Loans (notes, contact name, amount)
- [ ] Contacts (name, phone, email)
- [ ] Folders (name)

### Search Screen
- [ ] Search bar auto-focused on open
- [ ] Recent searches list (stored in memory, max 10)
- [ ] Clear recent searches button
- [ ] Results appear live as user types (≥2 characters)
- [ ] Results grouped by type: Expenses | Income | Loans | Contacts | Folders
- [ ] "No results" empty state with icon

### Search Filters
- [ ] Filter chips below search bar: All / Expenses / Income / Loans / Contacts
- [ ] Date range filter (tap calendar icon)
- [ ] Amount range filter (min, max)

### Result Items
- [ ] **Expense result:** category icon, description, amount (red), date, folder
- [ ] **Income result:** category icon, description, amount (green), date
- [ ] **Loan result:** contact avatar, principal, type (given/taken), status
- [ ] **Contact result:** avatar, name, outstanding balance
- [ ] **Folder result:** folder icon (colored), name, parent folder
- [ ] Tapping any result navigates to its detail screen

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
- [ ] Implement debounced search (300 ms after last keystroke)
- [ ] Run all sub-queries in parallel using `Future.wait`
- [ ] Merge and sort results by relevance (exact match first, then partial)

### Amount Search
- [ ] If query is a valid number, also search by exact amount match
- [ ] e.g., searching "500" shows expenses/income with amount = 500

### Person Search
- [ ] Searching a name finds:
  - Contacts with that name
  - Expenses linked to that contact
  - Loans linked to that contact

### Providers
- [ ] `searchQueryProvider` — `StateProvider<String>`
- [ ] `searchResultsProvider` — `FutureProvider<SearchResults>` (debounced)
- [ ] `SearchResults` model: `expenses, income, loans, contacts, folders`

---

## Acceptance Criteria
- Results appear within 300 ms of typing (on device with 10,000+ records)
- Amount search finds exact matches
- Tapping any result opens the correct detail screen
- Recent searches persist within the session
