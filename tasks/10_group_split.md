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
- [ ] `Group`, `GroupMember`, `GroupTransaction`, `GroupSplit` models
- [ ] `SplitType` enum: equal, custom, percentage

### Split Calculation Utilities
- [ ] `SplitCalculator.equalSplit(total, memberCount) → List<double>`
- [ ] `SplitCalculator.customSplit(List<double> amounts) → List<double>` — validates sum == total
- [ ] `SplitCalculator.percentageSplit(total, List<double> percentages) → List<double>`

### Settlement Calculation
- [ ] `GroupSettlementCalculator.getBalances(groupId) → Map<memberId, double>`
  - Positive = member is owed money; Negative = member owes money
- [ ] `GroupSettlementCalculator.getOptimalSettlements(balances) → List<Settlement>`
  - Uses greedy simplification to minimize number of transfers

### Repository
- [ ] `GroupRepository`:
  - [ ] `getAllGroups() → List<Group>`
  - [ ] `getGroupById(String id) → Group?`
  - [ ] `createGroup(Group, List<GroupMember>)`
  - [ ] `updateGroup(Group)`
  - [ ] `archiveGroup(String id)`
  - [ ] `getMembers(String groupId) → List<GroupMember>`
  - [ ] `addMember(GroupMember)`
  - [ ] `removeMember(String memberId)`
  - [ ] `getTransactions(String groupId) → List<GroupTransaction>`
  - [ ] `addTransaction(GroupTransaction, List<GroupSplit>)`
  - [ ] `editTransaction(GroupTransaction, List<GroupSplit>)`
  - [ ] `deleteTransaction(String id)`
  - [ ] `markSplitSettled(String splitId)`
  - [ ] `getGroupBalances(String groupId) → Map<String, double>`

### Group List Screen
- [ ] Cards: group name, member count, total spent, your balance
- [ ] Status badge (active / settled)
- [ ] FAB to create group

### Create / Edit Group Screen
- [ ] Group name, description, icon, color
- [ ] Add members:
  - [ ] "You" always included
  - [ ] Add from contacts or enter name manually
- [ ] Save

### Group Detail Screen
- [ ] Header: name, total spent, member count
- [ ] Tabs:
  - [ ] **Expenses** — list of group transactions
  - [ ] **Balances** — who owes whom
  - [ ] **Settlements** — suggested transactions to settle up
- [ ] FAB to add expense

### Add Group Expense Screen
- [ ] Description, total amount, date
- [ ] Paid by: member selector
- [ ] Split type: Equal / Custom / Percentage
- [ ] Equal split: auto-divide, show each share
- [ ] Custom split: amount input per member; validate sum == total
- [ ] Percentage split: % input per member; validate sum == 100%
- [ ] Save → create `group_transaction` + `group_transaction_splits`

### Balances Tab
- [ ] Net balance per member (positive = owed, negative = owes)
- [ ] "Mark as Settled" on individual split or bulk settle per member pair

### Settlements Tab
- [ ] Optimal settlement list (e.g., "Alice → Bob: ₹500")
- [ ] Tap to record settlement (creates a ₹0 split or marks splits as settled)

### Providers
- [ ] `groupsProvider` — `FutureProvider<List<Group>>`
- [ ] `groupDetailProvider(groupId)` — transactions + balances

---

## Acceptance Criteria
- Equal split divides correctly including remainders (distribute 1 unit to first members)
- Custom split validates total equals expense amount before saving
- Balance calculation is consistent with transaction history
- Settlements minimize number of transfers
