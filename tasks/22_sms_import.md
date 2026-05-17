# Task 22 — SMS Import (Module 22 / v3.0)

## Goal
Parse bank transaction SMS messages on Android to automatically create expense/income entries. iOS shows manual entry fallback (iOS restricts SMS access).

---

## Tasks

### Platform Notes
- [x] Android: `telephony` package can read SMS inbox
- [x] iOS: SMS access not available → show "Import manually" UI (paste SMS text)
- [x] Gate SMS features behind `Platform.isAndroid` check

### Package Setup
- [x] Add `telephony` to `pubspec.yaml` (Android only)
- [x] Add permission to `AndroidManifest.xml`: `READ_SMS`, `RECEIVE_SMS`
- [x] Request `READ_SMS` permission at runtime before first access

### Supported Bank Formats
Parse SMS from major Indian banks/services:

| Bank/Service | Pattern |
|---|---|
| HDFC | `Rs.{amount} debited/credited from A/c ...` |
| SBI | `Your A/c ...debited by Rs {amount}` |
| ICICI | `ICICI Bank Acct ... debited for Rs {amount}` |
| Axis | `INR {amount} debited from your Axis Bank A/c` |
| Paytm | `Rs. {amount} paid to {merchant}` |
| GPay / PhonePe | `Rs {amount} sent to {UPI ID}` |
| Credit card | `spent Rs.{amount} at {merchant}` |

### SMS Parser Service
- [x] `SMSParserService`:
  - [x] `isBankSMS(SmsMessage msg) → bool`
    - Sender must match known short codes: `HDFCBK`, `SBIINB`, `ICICIB`, `AXISBK`, `PAYTM`, etc.
  - [x] `parseSMS(SmsMessage msg) → ParsedSMS?`
    - [x] Extract `amount` via regex: `(?:rs\.?|inr|₹)\s*(\d+(?:,\d+)*(?:\.\d{2})?)`
    - [x] Extract `type`: look for keywords `debit|debited|spent|paid|withdrawn` → expense; `credit|credited|received|deposit` → income
    - [x] Extract `merchant`: text after "at", "to", "from" keywords
    - [x] Extract `date`: from SMS timestamp (`SmsMessage.date`)
    - [x] Return `ParsedSMS(amount, type, merchant, date, rawBody)`

### SMS Import Flow
1. User opens SMS Import screen
2. App reads last 30 days of SMS (filtered to bank senders)
3. Each SMS is parsed; only bank transaction SMS shown
4. SMS shown in list with parsed preview: amount, type, merchant, date
5. User reviews and selects which to import (checkbox)
6. Tap "Import Selected":
   - For each selected: create expense/income record with parsed data
   - Mark as `imported` in `sms_import_log`
   - Let user assign wallet, folder, category per record (or bulk assign)
7. Already-imported SMS filtered out on next open (by checking `sms_import_log`)

### SMS Import Screen
- [x] Filter bar: All / Debits / Credits / Unreviewed
- [x] Each SMS card:
  - Bank icon + sender name
  - Parsed: amount (red/green), merchant, date
  - Raw SMS body (collapsible)
  - Status: Pending / Imported / Skipped
- [x] "Select All" / "Deselect All"
- [x] "Import Selected" → bulk import dialog
- [x] "Skip" swipe action on individual SMS

### Bulk Import Dialog
- [x] Wallet selector (applied to all selected)
- [x] Folder selector (applied to all selected)
- [x] Category auto-assigned per merchant (user can override individually after)
- [x] "Confirm Import" button

### iOS Manual Paste Fallback
- [x] Large text area to paste SMS text
- [x] "Parse" button → runs `parseSMS` on pasted text
- [x] Shows parsed result for review → same Add Expense pre-fill flow as OCR

### Duplicate Detection
- [x] Before import, check `expenses` / `income` table for same amount + date ± 1 day
- [x] Warn user: "A similar transaction already exists. Import anyway?"

### Database
- [x] Log all seen SMS in `sms_import_log` (even skipped ones)
- [x] `status`: `pending | imported | skipped | failed`
- [x] On next open, filter out `status IN ('imported', 'skipped')`

### Auto-Import (Optional Setting)
- [x] Register `RECEIVE_SMS` broadcast receiver
- [x] On new bank SMS received → parse → show notification: "New transaction detected. Tap to review"
- [x] Tapping notification opens SMS Import screen pre-filtered to that SMS

---

## Acceptance Criteria
- Correctly parses debit/credit from top 5 Indian banks
- Duplicate detection prevents double-entry
- Imported records appear immediately in expense/income lists
- iOS users see a usable manual paste fallback
- Permission denial handled gracefully with explanation
