# Task 09 — Contact Ledger (Module 9)

## Goal
Maintain a list of people (friends, family, borrowers, customers) and see their full transaction and loan history.

---

## Database Table
```sql
CREATE TABLE contacts (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  phone       TEXT,
  email       TEXT,
  category    TEXT DEFAULT 'other',  -- friend | family | borrower | customer | other
  avatar_path TEXT,
  notes       TEXT,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);
```

---

## Tasks

### Model
- [x] `Contact` model with `fromMap` / `toMap`
- [x] `ContactCategory` enum: friend, family, borrower, customer, other
- [x] Computed field: `outstandingBalance` (loans given − loans taken, net)

### Repository
- [x] `ContactRepository`:
  - [x] `getAllContacts() → List<Contact>`
  - [x] `getContactById(String id) → Contact?`
  - [x] `searchContacts(String query) → List<Contact>`
  - [x] `createContact(Contact)`
  - [x] `updateContact(Contact)`
  - [x] `deleteContact(String id)` — soft delete check (block if has active loans)
  - [x] `getContactLedger(String id)` → combined expenses/income/loans linked to contact

### Contact List Screen
- [x] Alphabetically grouped list (A–Z section headers)
- [x] Each row: avatar/initials, name, category badge, outstanding balance
- [x] Search bar at top (real-time filter)
- [x] FAB to add contact
- [x] Swipe to edit / delete

### Add / Edit Contact Screen
- [x] Name (required)
- [x] Phone number
- [x] Email
- [x] Category selector
- [x] Avatar: pick from gallery or auto-generate initials avatar
- [x] Notes
- [x] Save → `createContact` / `updateContact`

### Contact Detail Screen
- [x] Contact info header (avatar, name, phone, email)
- [x] Outstanding balance summary (net amount owed to/by)
- [x] Tabs:
  - [x] **Transactions** — linked expenses and income
  - [x] **Loans** — active and settled loans with this contact
  - [x] **Groups** — shared group splits involving this contact
- [x] "Add Expense", "Add Loan" quick action buttons

### Outstanding Balance Calculation
```sql
SELECT
  COALESCE(SUM(CASE WHEN l.type = 'given' THEN remaining ELSE -remaining END), 0)
AS net_balance
FROM loans l
WHERE l.contact_id = ? AND l.status != 'settled';
```
- [x] Implement via `LoanRepository.getNetBalanceForContact(contactId)`

### Providers
- [x] `contactsProvider` — `FutureProvider<List<Contact>>`
- [x] `contactDetailProvider(contactId)` — contact + ledger summary

---

## Acceptance Criteria
- Contacts link to expenses, income, and loans correctly
- Outstanding balance reflects net of all active loans
- Deleting a contact is blocked if they have active loans
- Search works in real time as user types
