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
- [ ] `Contact` model with `fromMap` / `toMap`
- [ ] `ContactCategory` enum: friend, family, borrower, customer, other
- [ ] Computed field: `outstandingBalance` (loans given − loans taken, net)

### Repository
- [ ] `ContactRepository`:
  - [ ] `getAllContacts() → List<Contact>`
  - [ ] `getContactById(String id) → Contact?`
  - [ ] `searchContacts(String query) → List<Contact>`
  - [ ] `createContact(Contact)`
  - [ ] `updateContact(Contact)`
  - [ ] `deleteContact(String id)` — soft delete check (block if has active loans)
  - [ ] `getContactLedger(String id)` → combined expenses/income/loans linked to contact

### Contact List Screen
- [ ] Alphabetically grouped list (A–Z section headers)
- [ ] Each row: avatar/initials, name, category badge, outstanding balance
- [ ] Search bar at top (real-time filter)
- [ ] FAB to add contact
- [ ] Swipe to edit / delete

### Add / Edit Contact Screen
- [ ] Name (required)
- [ ] Phone number
- [ ] Email
- [ ] Category selector
- [ ] Avatar: pick from gallery or auto-generate initials avatar
- [ ] Notes
- [ ] Save → `createContact` / `updateContact`

### Contact Detail Screen
- [ ] Contact info header (avatar, name, phone, email)
- [ ] Outstanding balance summary (net amount owed to/by)
- [ ] Tabs:
  - [ ] **Transactions** — linked expenses and income
  - [ ] **Loans** — active and settled loans with this contact
  - [ ] **Groups** — shared group splits involving this contact
- [ ] "Add Expense", "Add Loan" quick action buttons

### Outstanding Balance Calculation
```sql
SELECT
  COALESCE(SUM(CASE WHEN l.type = 'given' THEN remaining ELSE -remaining END), 0)
AS net_balance
FROM loans l
WHERE l.contact_id = ? AND l.status != 'settled';
```
- [ ] Implement via `LoanRepository.getNetBalanceForContact(contactId)`

### Providers
- [ ] `contactsProvider` — `FutureProvider<List<Contact>>`
- [ ] `contactDetailProvider(contactId)` — contact + ledger summary

---

## Acceptance Criteria
- Contacts link to expenses, income, and loans correctly
- Outstanding balance reflects net of all active loans
- Deleting a contact is blocked if they have active loans
- Search works in real time as user types
