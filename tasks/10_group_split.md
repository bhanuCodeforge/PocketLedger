# Task 10 — Group Split (Module 10)

## Goal
Split shared expenses (trips, dinners, rent) among group members with settlement tracking.

---

## Database Tables
```sql
CREATE TABLE groups (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  description TEXT,
  icon        TEXT,
  color       TEXT,
  status      TEXT DEFAULT 'active',  -- active | settled | archived
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);

CREATE TABLE group_members (
  id          TEXT PRIMARY KEY,
  group_id    TEXT NOT NULL,
  contact_id  TEXT,                  -- NULL = "You" (app user)
  name        TEXT NOT NULL,         -- display name
  created_at  TEXT NOT NULL,
  FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
  FOREIGN KEY (contact_id) REFERENCES contacts(id)
);

CREATE TABLE group_transactions (
  id              TEXT PRIMARY KEY,
  group_id        TEXT NOT NULL,
  description     TEXT NOT NULL,
  total_amount    REAL NOT NULL,
  date            TEXT NOT NULL,
  paid_by_member  TEXT NOT NULL,     -- group_members.id
  split_type      TEXT DEFAULT 'equal',  -- equal | custom | percentage
  notes           TEXT,
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL,
  FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
  FOREIGN KEY (paid_by_member) REFERENCES group_members(id)
);

CREATE TABLE group_transaction_splits (
  id              TEXT PRIMARY KEY,
  transaction_id  TEXT NOT NULL,
  member_id       TEXT NOT NULL,
  amount          REAL NOT NULL,
  is_settled      INTEGER DEFAULT 0,
  settled_at      TEXT,
  FOREIGN KEY (transaction_id) REFERENCES group_transactions(id) ON DELETE CASCADE,
  FOREIGN KEY (member_id) REFERENCES group_members(id)
);
```

---

## Tasks

### Models
- [x] `Group`, `GroupMember`, `GroupTransaction`, `GroupSplit` models
- [x] `SplitType` enum: equal, custom, percentage

### Split Calculation Utilities
- [x] `SplitCalculator.equalSplit(total, memberCount) → List<double>`
- [x] `SplitCalculator.customSplit(List<double> amounts) → List<double>` — validates sum == total
- [x] `SplitCalculator.percentageSplit(total, List<double> percentages) → List<double>`

### Settlement Calculation
- [x] `GroupSettlementCalculator.getBalances(groupId) → Map<memberId, double>`
  - Positive = member is owed money; Negative = member owes money
- [x] `GroupSettlementCalculator.getOptimalSettlements(balances) → List<Settlement>`
  - Uses greedy simplification to minimize number of transfers

### Repository
- [x] `GroupRepository`:
  - [x] `getAllGroups() → List<Group>`
  - [x] `getGroupById(String id) → Group?`
  - [x] `createGroup(Group, List<GroupMember>)`
  - [x] `updateGroup(Group)`
  - [x] `archiveGroup(String id)`
  - [x] `getMembers(String groupId) → List<GroupMember>`
  - [x] `addMember(GroupMember)`
  - [x] `removeMember(String memberId)`
  - [x] `getTransactions(String groupId) → List<GroupTransaction>`
  - [x] `addTransaction(GroupTransaction, List<GroupSplit>)`
  - [x] `editTransaction(GroupTransaction, List<GroupSplit>)`
  - [x] `deleteTransaction(String id)`
  - [x] `markSplitSettled(String splitId)`
  - [x] `getGroupBalances(String groupId) → Map<String, double>`

### Group List Screen
- [x] Cards: group name, member count, total spent, your balance
- [x] Status badge (active / settled)
- [x] FAB to create group

### Create / Edit Group Screen
- [x] Group name, description, icon, color
- [x] Add members:
  - [x] "You" always included
  - [x] Add from contacts or enter name manually
- [x] Save

### Group Detail Screen
- [x] Header: name, total spent, member count
- [x] Tabs:
  - [x] **Expenses** — list of group transactions
  - [x] **Balances** — who owes whom
  - [x] **Settlements** — suggested transactions to settle up
- [x] FAB to add expense

### Add Group Expense Screen
- [x] Description, total amount, date
- [x] Paid by: member selector
- [x] Split type: Equal / Custom / Percentage
- [x] Equal split: auto-divide, show each share
- [x] Custom split: amount input per member; validate sum == total
- [x] Percentage split: % input per member; validate sum == 100%
- [x] Save → create `group_transaction` + `group_transaction_splits`

### Balances Tab
- [x] Net balance per member (positive = owed, negative = owes)
- [x] "Mark as Settled" on individual split or bulk settle per member pair

### Settlements Tab
- [x] Optimal settlement list (e.g., "Alice → Bob: ₹500")
- [x] Tap to record settlement (creates a ₹0 split or marks splits as settled)

### Providers
- [x] `groupsProvider` — `FutureProvider<List<Group>>`
- [x] `groupDetailProvider(groupId)` — transactions + balances

---

## Acceptance Criteria
- Equal split divides correctly including remainders (distribute 1 unit to first members)
- Custom split validates total equals expense amount before saving
- Balance calculation is consistent with transaction history
- Settlements minimize number of transfers
