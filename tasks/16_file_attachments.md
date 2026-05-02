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
- [ ] Base path: `{app_documents_dir}/attachments/{entity_type}/{entity_id}/`
- [ ] Copy picked files into above path (do NOT reference original location)
- [ ] Use UUID as file name to avoid conflicts: `{uuid}.jpg`
- [ ] Store relative path in DB (reconstruct absolute at runtime with `path_provider`)

### Attachment Service
- [ ] `AttachmentService`:
  - [ ] `pickFromGallery() → File?`
  - [ ] `pickFromCamera() → File?`
  - [ ] `saveAttachment(File source, String entityType, String entityId) → Attachment`
  - [ ] `deleteAttachment(Attachment)` — removes file + DB record
  - [ ] `getAttachments(String entityId, String entityType) → List<Attachment>`
  - [ ] `getAbsolutePath(String relativePath) → String`

### Repository
- [ ] `AttachmentRepository`:
  - [ ] `insertAttachment(Attachment)`
  - [ ] `getAttachmentsForEntity(String entityId, String entityType)`
  - [ ] `deleteAttachment(String id)`

### Attachment UI Component (reusable widget)
- [ ] `AttachmentPicker` widget:
  - [ ] Horizontally scrollable thumbnail list
  - [ ] "+" add button at end
  - [ ] On tap "+": bottom sheet with "Camera" / "Gallery" options
  - [ ] Thumbnail: shows image preview for images, PDF icon for PDFs
  - [ ] Tap thumbnail → full-screen viewer
  - [ ] Long-press thumbnail → delete option

### Full-Screen Image Viewer
- [ ] Pinch-to-zoom
- [ ] Swipe between multiple attachments
- [ ] Share button (using `share_plus`)
- [ ] Delete button (with confirm)

### Permissions
- [ ] Camera: requested on first camera use
- [ ] Gallery / Storage: requested on first gallery use
- [ ] Handle permanent denial gracefully (show settings redirect)

### Storage Size Warning
- [ ] Track total attachment storage size
- [ ] Warn user when attachments exceed 500 MB: "Attachment storage is large. Consider backup."

### Orphan Cleanup
- [ ] On app startup, scan `attachments` dir for files with no matching DB record
- [ ] Delete orphan files silently

---

## Acceptance Criteria
- Images copied to app documents, not linked to gallery (survives gallery deletion)
- Full-screen viewer works for single and multiple attachments
- Deleting attachment removes both file and DB record
- Attachment thumbnails appear correctly in expense/income/loan forms
