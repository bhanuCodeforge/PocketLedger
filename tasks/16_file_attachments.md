# Task 16 — File Attachments (Module 16)

## Goal
Attach receipt images, notes documents, and agreements to expenses, income, and loans. Local storage only.

---

## Database Table
```sql
-- Already defined in expenses task; reproduced here for clarity:
CREATE TABLE attachments (
  id          TEXT PRIMARY KEY,
  entity_id   TEXT NOT NULL,
  entity_type TEXT NOT NULL,  -- expense | income | loan
  file_path   TEXT NOT NULL,  -- absolute local path inside app documents dir
  file_name   TEXT,
  file_type   TEXT,           -- image | pdf | other
  file_size   INTEGER,        -- bytes
  created_at  TEXT NOT NULL
);
```

---

## Tasks

### Attachment Storage Strategy
- [x] Base path: `{app_documents_dir}/attachments/{entity_type}/{entity_id}/`
- [x] Copy picked files into above path (do NOT reference original location)
- [x] Use UUID as file name to avoid conflicts: `{uuid}.jpg`
- [x] Store relative path in DB (reconstruct absolute at runtime with `path_provider`)

### Attachment Service
- [x] `AttachmentService`:
  - [x] `pickFromGallery() → File?`
  - [x] `pickFromCamera() → File?`
  - [x] `saveAttachment(File source, String entityType, String entityId) → Attachment`
  - [x] `deleteAttachment(Attachment)` — removes file + DB record
  - [x] `getAttachments(String entityId, String entityType) → List<Attachment>`
  - [x] `getAbsolutePath(String relativePath) → String`

### Repository
- [x] `AttachmentRepository`:
  - [x] `insertAttachment(Attachment)`
  - [x] `getAttachmentsForEntity(String entityId, String entityType)`
  - [x] `deleteAttachment(String id)`

### Attachment UI Component (reusable widget)
- [x] `AttachmentPicker` widget:
  - [x] Horizontally scrollable thumbnail list
  - [x] "+" add button at end
  - [x] On tap "+": bottom sheet with "Camera" / "Gallery" options
  - [x] Thumbnail: shows image preview for images, PDF icon for PDFs
  - [x] Tap thumbnail → full-screen viewer
  - [x] Long-press thumbnail → delete option

### Full-Screen Image Viewer
- [x] Pinch-to-zoom
- [x] Swipe between multiple attachments
- [x] Share button (using `share_plus`)
- [x] Delete button (with confirm)

### Permissions
- [x] Camera: requested on first camera use
- [x] Gallery / Storage: requested on first gallery use
- [x] Handle permanent denial gracefully (show settings redirect)

### Storage Size Warning
- [x] Track total attachment storage size
- [x] Warn user when attachments exceed 500 MB: "Attachment storage is large. Consider backup."

### Orphan Cleanup
- [x] On app startup, scan `attachments` dir for files with no matching DB record
- [x] Delete orphan files silently

---

## Acceptance Criteria
- Images copied to app documents, not linked to gallery (survives gallery deletion)
- Full-screen viewer works for single and multiple attachments
- Deleting attachment removes both file and DB record
- Attachment thumbnails appear correctly in expense/income/loan forms
