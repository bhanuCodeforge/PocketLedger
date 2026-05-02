# Task 05 — Folder Management (Module 5)

## Goal
Organize transactions into nested folders (Personal > Food, Business > Travel, etc.) with custom colors and icons.

---

## Database Table
```sql
CREATE TABLE folders (
  id          TEXT PRIMARY KEY,   -- UUID
  name        TEXT NOT NULL,
  parent_id   TEXT,               -- NULL for root folders; FK → folders(id)
  color       TEXT DEFAULT '#607D8B',
  icon        TEXT DEFAULT 'folder',
  status      TEXT DEFAULT 'active',  -- active | archived
  sort_order  INTEGER DEFAULT 0,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL,
  FOREIGN KEY (parent_id) REFERENCES folders(id)
);
```

---

## Tasks

### Model
- [ ] `Folder` model with `fromMap` / `toMap`
- [ ] `children` computed field: `List<Folder>` (populated in repository tree query)
- [ ] `depth` computed field (0 = root, 1 = child, 2 = grandchild — max depth 3)

### Repository
- [ ] `FolderRepository`:
  - [ ] `getAllFolders() → List<Folder>` (flat list)
  - [ ] `getFolderTree() → List<Folder>` (nested, children populated)
  - [ ] `getRootFolders() → List<Folder>`
  - [ ] `getChildFolders(String parentId) → List<Folder>`
  - [ ] `getFolderById(String id) → Folder?`
  - [ ] `createFolder(Folder)`
  - [ ] `updateFolder(Folder)`
  - [ ] `archiveFolder(String id)` — archives recursively
  - [ ] `reorderFolders(List<String> ids)` — updates sort_order

### Seed Data
- [ ] Insert default folders on first run:
  - [ ] Personal (root)
  - [ ] Food (child of Personal)
  - [ ] Grocery (child of Personal)
  - [ ] Utility (child of Personal)
  - [ ] Friends (root)
  - [ ] Business (root)

### Folder List Screen
- [ ] Tree view with expand/collapse per root folder
- [ ] Indented children (indent by depth)
- [ ] Each row: colored icon, folder name, transaction count badge
- [ ] FAB to add root folder
- [ ] "+" icon beside each folder to add a child
- [ ] Long-press → Edit / Archive / Add Child
- [ ] Drag-to-reorder within same parent level

### Add / Edit Folder Screen
- [ ] Folder name (required)
- [ ] Parent folder selector (dropdown of active root folders; empty = root)
- [ ] Color picker (16 preset palette)
- [ ] Icon picker (grid of ~30 material icons: food, car, home, work, etc.)
- [ ] Enforce max depth of 3 levels

### Archive Logic
- [ ] Archiving a parent folder archives all children
- [ ] Archived folders hidden from transaction form selectors
- [ ] Archived section visible in folder settings for reference

### Providers
- [ ] `foldersProvider` — `FutureProvider<List<Folder>>` (tree)
- [ ] `activeFoldersProvider` — flat list of active folders for dropdowns

---

## Acceptance Criteria
- Nested structure supports up to 3 levels deep
- Tree renders correctly with visual indentation
- Archiving parent cascades to children
- Folders persist and display in transaction forms
