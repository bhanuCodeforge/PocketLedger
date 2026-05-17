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
- [x] `Wallet` model with `fromMap` / `toMap`
- [x] `WalletType` enum: `cash`, `bank`, `upi`, `creditCard`, `business`, `other`
- [x] Computed field: `currentBalance` (opening_balance + income - expenses)

### Repository
- [x] `WalletRepository`:
  - [x] `getAllWallets() → List<Wallet>`
  - [x] `getActiveWallets() → List<Wallet>`
  - [x] `getWalletById(String id) → Wallet?`
  - [x] `createWallet(Wallet)`
  - [x] `updateWallet(Wallet)`
  - [x] `archiveWallet(String id)`
  - [x] `getWalletBalance(String id) → double` — computed from transactions

### Wallet List Screen
- [x] Show all active wallets as cards
- [x] Each card: name, type icon, current balance, color indicator
- [x] FAB to add new wallet
- [x] Long-press → Edit / Archive options
- [x] Swipe to archive with undo snackbar
- [x] Archived wallets section (collapsible, read-only)

### Add / Edit Wallet Screen
- [x] Wallet name (required)
- [x] Type selector (icon grid: Cash, Bank, UPI, Credit Card, Business, Other)
- [x] Opening balance input (numeric)
- [x] Color picker (10 preset colors)
- [x] Icon selector (optional override)
- [x] Validate: name not empty, balance ≥ 0
- [x] Save → `createWallet` or `updateWallet`

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
- [x] Implement above as `getWalletBalance`
- [x] Cache balance in Riverpod; invalidate when transaction added/edited/deleted

### Transfer Between Wallets (Bonus v1.0)
- [x] Transfer screen: from wallet, to wallet, amount, date, note
- [x] Creates an expense in source wallet + income in destination wallet linked by `transfer_id`

### Providers
- [x] `walletsProvider` — `StreamProvider<List<Wallet>>`
- [x] `walletBalanceProvider(walletId)` — `FutureProvider<double>`

---

## Edge Cases & Error Handling

### Balance Edge Cases
- [x] Credit card wallet: negative balance is valid and normal — display with red color, no error
- [x] Opening balance can be negative (e.g., wallet starts with debt)
- [x] Balance calculation must exclude archived wallets from total dashboard sum
- [x] Wallet transfer: if source has insufficient funds → warn but allow (soft warning, not hard block — credit cards can go negative)

### CRUD Edge Cases
- [x] Wallet name uniqueness: not enforced at DB level (allow two "Cash" wallets); duplicates are a UX choice
- [x] Archiving a wallet that is set as default in a recurring expense → show warning: "X recurring rules use this wallet. They will need to be updated."
- [x] Unarchive: if wallet was archived, "Unarchive" action in archived section restores `status = 'active'`
- [x] Last active wallet: block archiving if it's the only active wallet — show error: "At least one wallet is required"
- [x] Editing opening balance after transactions exist → show warning: "Changing opening balance will update all balance calculations retroactively"

### Data Integrity
- [x] Wallet delete is not supported (only archive) to preserve transaction history referential integrity
- [x] If `wallet_id` FK is violated (orphan transaction) → `DatabaseHelper.onUpgrade` must detect and log

---

## UI Micro-Interactions
- [x] Wallet cards: balance animates counting up/down when updated (number counter animation, 600 ms)
- [x] Add wallet FAB: expands into a bottom sheet (not a new screen) for speed
- [x] Swipe to archive: orange background with archive icon; undo snackbar for 4 seconds
- [x] Wallet type icons: animated icon switch when user selects type in add form
- [x] Negative balance: balance text turns red with a downward arrow prefix

---

## Acceptance Criteria
- Wallet balance always matches opening balance + income - expenses
- Archived wallets do not appear in transaction forms
- At least one wallet must exist at all times (block last archive)
- Wallet CRUD works fully offline
- Negative balances display correctly without errors
