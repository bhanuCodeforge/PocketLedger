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
- [x] `Folder` model with `fromMap` / `toMap`
- [x] `children` computed field: `List<Folder>` (populated in repository tree query)
- [x] `depth` computed field (0 = root, 1 = child, 2 = grandchild — max depth 3)

### Repository
- [x] `FolderRepository`:
  - [x] `getAllFolders() → List<Folder>` (flat list)
  - [x] `getFolderTree() → List<Folder>` (nested, children populated)
  - [x] `getRootFolders() → List<Folder>`
  - [x] `getChildFolders(String parentId) → List<Folder>`
  - [x] `getFolderById(String id) → Folder?`
  - [x] `createFolder(Folder)`
  - [x] `updateFolder(Folder)`
  - [x] `archiveFolder(String id)` — archives recursively
  - [x] `reorderFolders(List<String> ids)` — updates sort_order

### Seed Data
- [x] Insert default folders on first run:
  - [x] Personal (root)
  - [x] Food (child of Personal)
  - [x] Grocery (child of Personal)
  - [x] Utility (child of Personal)
  - [x] Friends (root)
  - [x] Business (root)

### Folder List Screen
- [x] Tree view with expand/collapse per root folder
- [x] Indented children (indent by depth)
- [x] Each row: colored icon, folder name, transaction count badge
- [x] FAB to add root folder
- [x] "+" icon beside each folder to add a child
- [x] Long-press → Edit / Archive / Add Child
- [x] Drag-to-reorder within same parent level

### Add / Edit Folder Screen
- [x] Folder name (required)
- [x] Parent folder selector (dropdown of active root folders; empty = root)
- [x] Color picker (16 preset palette)
- [x] Icon picker (grid of ~30 material icons: food, car, home, work, etc.)
- [x] Enforce max depth of 3 levels

### Archive Logic
- [x] Archiving a parent folder archives all children
- [x] Archived folders hidden from transaction form selectors
- [x] Archived section visible in folder settings for reference

### Providers
- [x] `foldersProvider` — `FutureProvider<List<Folder>>` (tree)
- [x] `activeFoldersProvider` — flat list of active folders for dropdowns

---

## Acceptance Criteria
- Nested structure supports up to 3 levels deep
- Tree renders correctly with visual indentation
- Archiving parent cascades to children
- Folders persist and display in transaction forms
