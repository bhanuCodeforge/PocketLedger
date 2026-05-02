# Task 21 — OCR Receipt Scan (Module 21 / v3.0)

## Goal
Use on-device ML to scan a receipt photo and auto-fill expense fields (amount, date, merchant name).

---

## Tasks

### Package Setup
- [ ] Add `google_mlkit_text_recognition` to `pubspec.yaml`
- [ ] Add `image_picker` (already in project)
- [ ] Android: minSdk already 21 ✓; add ML Kit model dependency in `build.gradle`
- [ ] iOS: add `NSCameraUsageDescription` (already present)
- [ ] Test on physical device (emulator ML Kit support is limited)

### OCR Service
- [ ] `OCRService`:
  - [ ] `scanImage(File imageFile) → OCRResult`
    1. Load image via `InputImage.fromFile`
    2. Run `TextRecognizer().processImage(inputImage)`
    3. Extract raw `RecognizedText`
    4. Pass to `ReceiptParser.parse(text)`
    5. Return `OCRResult`
  - [ ] `dispose()` — release `TextRecognizer`

### Receipt Parser
- [ ] `ReceiptParser.parse(RecognizedText text) → ParsedReceipt`
  - [ ] **Amount extraction:**
    - [ ] Regex: `(?:total|amount|grand total|rs\.?|inr|₹)\s*:?\s*(\d+[\.,]\d{2})` (case-insensitive)
    - [ ] Find largest currency-like number as fallback
    - [ ] Handle both `1,234.56` and `1234.56` formats
  - [ ] **Date extraction:**
    - [ ] Regex patterns for: `DD/MM/YYYY`, `DD-MM-YYYY`, `DD MMM YYYY`, `MMM DD YYYY`
    - [ ] Validate parsed date is within last 90 days (reject future dates)
  - [ ] **Merchant name:**
    - [ ] Use first 1–2 non-empty lines of the receipt (usually business name)
    - [ ] Strip common suffixes: "PVT LTD", "& CO", "RESTAURANT"
  - [ ] **Category suggestion:**
    - [ ] Keyword map: `{restaurant, cafe, food → Food}`, `{pharmacy, medical → Medical}`, etc.
    - [ ] Match merchant name + line items against keyword map
  - [ ] Return `ParsedReceipt(amount?, date?, merchant?, suggestedCategory?)`

### OCR Scan Screen
- [ ] Entry points:
  - [ ] FAB on Add Expense screen → "Scan Receipt"
  - [ ] Standalone `/ocr` route
- [ ] Camera preview with capture button
- [ ] "Pick from Gallery" option
- [ ] After capture:
  - [ ] Show processing indicator ("Reading receipt…")
  - [ ] Display parsed result preview:
    - Amount (editable)
    - Date (editable)
    - Merchant/Description (editable)
    - Suggested category (editable)
  - [ ] "Use this" button → navigates to Add Expense with pre-filled fields
  - [ ] "Try again" button → re-scan
- [ ] Show confidence indicator (high/medium/low based on how many fields parsed)

### Low Confidence Handling
- [ ] If amount not found → show warning "Amount not detected, please enter manually"
- [ ] If date not found → default to today
- [ ] Never silently use wrong data — always show parsed values for user review before applying

### Image Pre-Processing
- [ ] Crop to document bounds if possible (use `image` package for rotation correction)
- [ ] Apply grayscale for better OCR accuracy
- [ ] Resize to max 1920px on longest edge before processing (speed optimization)

### Privacy
- [ ] All OCR processing is on-device (no network calls)
- [ ] Original receipt image is offered for saving as attachment (user choice)
- [ ] Never send receipt image to any server

---

## Acceptance Criteria
- Amount correctly parsed from 90%+ of standard Indian retail receipts
- Date parsed correctly when in a standard format
- All parsed fields shown for user review before being applied
- Processing completes in < 3 seconds on mid-range device
- No internet required
