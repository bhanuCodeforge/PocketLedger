# Task 04 — Wallet Management (Module 4)

## Goal
Track money containers (Cash, Bank, UPI, Credit Card, etc.) with balances derived from transactions.

---

## Database Table
```sql
CREATE TABLE wallets (
  id              TEXT PRIMARY KEY,   -- UUID
  name            TEXT NOT NULL,
  type            TEXT NOT NULL,      -- cash | bank | upi | credit_card | business | other
  opening_balance REAL DEFAULT 0.0,
  color           TEXT,               -- hex color
  icon            TEXT,               -- icon identifier
  status          TEXT DEFAULT 'active',  -- active | archived
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL
);
```

---

## Tasks

### Model
- [ ] `Wallet` model with `fromMap` / `toMap`
- [ ] `WalletType` enum: `cash`, `bank`, `upi`, `creditCard`, `business`, `other`
- [ ] Computed field: `currentBalance` (opening_balance + income - expenses)

### Repository
- [ ] `WalletRepository`:
  - [ ] `getAllWallets() → List<Wallet>`
  - [ ] `getActiveWallets() → List<Wallet>`
  - [ ] `getWalletById(String id) → Wallet?`
  - [ ] `createWallet(Wallet)`
  - [ ] `updateWallet(Wallet)`
  - [ ] `archiveWallet(String id)`
  - [ ] `getWalletBalance(String id) → double` — computed from transactions

### Wallet List Screen
- [ ] Show all active wallets as cards
- [ ] Each card: name, type icon, current balance, color indicator
- [ ] FAB to add new wallet
- [ ] Long-press → Edit / Archive options
- [ ] Swipe to archive with undo snackbar
- [ ] Archived wallets section (collapsible, read-only)

### Add / Edit Wallet Screen
- [ ] Wallet name (required)
- [ ] Type selector (icon grid: Cash, Bank, UPI, Credit Card, Business, Other)
- [ ] Opening balance input (numeric)
- [ ] Color picker (10 preset colors)
- [ ] Icon selector (optional override)
- [ ] Validate: name not empty, balance ≥ 0
- [ ] Save → `createWallet` or `updateWallet`

### Balance Calculation Query
```sql
SELECT
  w.opening_balance
  + COALESCE(SUM(CASE WHEN i.wallet_id = w.id THEN i.amount ELSE 0 END), 0)
  - COALESCE(SUM(CASE WHEN e.wallet_id = w.id THEN e.amount ELSE 0 END), 0)
AS balance
FROM wallets w
LEFT JOIN income i ON i.wallet_id = w.id
LEFT JOIN expenses e ON e.wallet_id = w.id
WHERE w.id = ?
GROUP BY w.id;
```
- [ ] Implement above as `getWalletBalance`
- [ ] Cache balance in Riverpod; invalidate when transaction added/edited/deleted

### Transfer Between Wallets (Bonus v1.0)
- [ ] Transfer screen: from wallet, to wallet, amount, date, note
- [ ] Creates an expense in source wallet + income in destination wallet linked by `transfer_id`

### Providers
- [ ] `walletsProvider` — `StreamProvider<List<Wallet>>`
- [ ] `walletBalanceProvider(walletId)` — `FutureProvider<double>`

---

## Edge Cases & Error Handling

### Balance Edge Cases
- [ ] Credit card wallet: negative balance is valid and normal — display with red color, no error
- [ ] Opening balance can be negative (e.g., wallet starts with debt)
- [ ] Balance calculation must exclude archived wallets from total dashboard sum
- [ ] Wallet transfer: if source has insufficient funds → warn but allow (soft warning, not hard block — credit cards can go negative)

### CRUD Edge Cases
- [ ] Wallet name uniqueness: not enforced at DB level (allow two "Cash" wallets); duplicates are a UX choice
- [ ] Archiving a wallet that is set as default in a recurring expense → show warning: "X recurring rules use this wallet. They will need to be updated."
- [ ] Unarchive: if wallet was archived, "Unarchive" action in archived section restores `status = 'active'`
- [ ] Last active wallet: block archiving if it's the only active wallet — show error: "At least one wallet is required"
- [ ] Editing opening balance after transactions exist → show warning: "Changing opening balance will update all balance calculations retroactively"

### Data Integrity
- [ ] Wallet delete is not supported (only archive) to preserve transaction history referential integrity
- [ ] If `wallet_id` FK is violated (orphan transaction) → `DatabaseHelper.onUpgrade` must detect and log

---

## UI Micro-Interactions
- [ ] Wallet cards: balance animates counting up/down when updated (number counter animation, 600 ms)
- [ ] Add wallet FAB: expands into a bottom sheet (not a new screen) for speed
- [ ] Swipe to archive: orange background with archive icon; undo snackbar for 4 seconds
- [ ] Wallet type icons: animated icon switch when user selects type in add form
- [ ] Negative balance: balance text turns red with a downward arrow prefix

---

## Acceptance Criteria
- Wallet balance always matches opening balance + income - expenses
- Archived wallets do not appear in transaction forms
- At least one wallet must exist at all times (block last archive)
- Wallet CRUD works fully offline
- Negative balances display correctly without errors
