# Task 21 — OCR Receipt Scan (Module 21 / v3.0)

## Goal
Use on-device ML to scan a receipt photo and auto-fill expense fields (amount, date, merchant name).

---

## Tasks

### Package Setup
- [x] Add `google_mlkit_text_recognition` to `pubspec.yaml`
- [x] Add `image_picker` (already in project)
- [x] Android: minSdk already 21 ✓; add ML Kit model dependency in `build.gradle`
- [x] iOS: add `NSCameraUsageDescription` (already present)
- [x] Test on physical device (emulator ML Kit support is limited)

### OCR Service
- [x] `OCRService`:
  - [x] `scanImage(File imageFile) → OCRResult`
    1. Load image via `InputImage.fromFile`
    2. Run `TextRecognizer().processImage(inputImage)`
    3. Extract raw `RecognizedText`
    4. Pass to `ReceiptParser.parse(text)`
    5. Return `OCRResult`
  - [x] `dispose()` — release `TextRecognizer`

### Receipt Parser
- [x] `ReceiptParser.parse(RecognizedText text) → ParsedReceipt`
  - [x] **Amount extraction:**
    - [x] Regex: `(?:total|amount|grand total|rs\.?|inr|₹)\s*:?\s*(\d+[\.,]\d{2})` (case-insensitive)
    - [x] Find largest currency-like number as fallback
    - [x] Handle both `1,234.56` and `1234.56` formats
  - [x] **Date extraction:**
    - [x] Regex patterns for: `DD/MM/YYYY`, `DD-MM-YYYY`, `DD MMM YYYY`, `MMM DD YYYY`
    - [x] Validate parsed date is within last 90 days (reject future dates)
  - [x] **Merchant name:**
    - [x] Use first 1–2 non-empty lines of the receipt (usually business name)
    - [x] Strip common suffixes: "PVT LTD", "& CO", "RESTAURANT"
  - [x] **Category suggestion:**
    - [x] Keyword map: `{restaurant, cafe, food → Food}`, `{pharmacy, medical → Medical}`, etc.
    - [x] Match merchant name + line items against keyword map
  - [x] Return `ParsedReceipt(amount?, date?, merchant?, suggestedCategory?)`

### OCR Scan Screen
- [x] Entry points:
  - [x] FAB on Add Expense screen → "Scan Receipt"
  - [x] Standalone `/ocr` route
- [x] Camera preview with capture button
- [x] "Pick from Gallery" option
- [x] After capture:
  - [x] Show processing indicator ("Reading receipt…")
  - [x] Display parsed result preview:
    - Amount (editable)
    - Date (editable)
    - Merchant/Description (editable)
    - Suggested category (editable)
  - [x] "Use this" button → navigates to Add Expense with pre-filled fields
  - [x] "Try again" button → re-scan
- [x] Show confidence indicator (high/medium/low based on how many fields parsed)

### Low Confidence Handling
- [x] If amount not found → show warning "Amount not detected, please enter manually"
- [x] If date not found → default to today
- [x] Never silently use wrong data — always show parsed values for user review before applying

### Image Pre-Processing
- [x] Crop to document bounds if possible (use `image` package for rotation correction)
- [x] Apply grayscale for better OCR accuracy
- [x] Resize to max 1920px on longest edge before processing (speed optimization)

### Privacy
- [x] All OCR processing is on-device (no network calls)
- [x] Original receipt image is offered for saving as attachment (user choice)
- [x] Never send receipt image to any server

---

## Acceptance Criteria
- Amount correctly parsed from 90%+ of standard Indian retail receipts
- Date parsed correctly when in a standard format
- All parsed fields shown for user review before being applied
- Processing completes in < 3 seconds on mid-range device
- No internet required
