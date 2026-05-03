# TC-10 — Bulk Product Import
**Module:** Bulk Import via Excel Upload  
**Based on:** EPIC-08

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Pass |
| ❌ | Fail |
| ⏳ | Not Executed |

---

## TC-10-01 — File Upload Validation

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-10-01-01 | Upload valid .xlsx file | Admin logged in | 1. Navigate to `/uploads/new`<br>2. Select valid `.xlsx` file<br>3. Submit | File stored in Active Storage; success flash | ⏳ |
| TC-10-01-02 | Upload .csv file rejected | — | 1. Select `.csv` file and submit | 422; "File must be .xlsx" | ⏳ |
| TC-10-01-03 | Upload .xls (old Excel) rejected | — | 1. Select `.xls` file and submit | 422; validation error | ⏳ |
| TC-10-01-04 | Upload without file | — | 1. Submit without selecting file | 422; "File can't be blank" | ⏳ |
| TC-10-01-05 | File size limit enforced | File > allowed max size | 1. Try to upload oversized file | 422; size validation error | ⏳ |

---

## TC-10-02 — Import Job Processing

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-10-02-01 | SolidQueue job enqueued after upload | Valid file uploaded | 1. Upload file | Import job queued in SolidQueue; visible in SolidQueue dashboard | ⏳ |
| TC-10-02-02 | Products created from sheet rows | Valid xlsx with new products | 1. Run import job | New products created; count matches new rows | ⏳ |
| TC-10-02-03 | Existing product updated by barcode match | xlsx row with existing barcode | 1. Run import with updated name/price | Existing product name/price updated; no duplicate created | ⏳ |
| TC-10-02-04 | Vendor auto-created if not found | xlsx has unknown vendor name | 1. Run import | Vendor created; product linked to new vendor | ⏳ |
| TC-10-02-05 | Brand auto-created if not found | xlsx has unknown brand | 1. Run import | Brand created; product linked | ⏳ |
| TC-10-02-06 | Child product parent linkage by sheet order | Parent row above child rows | 1. Import sheet with parent then children | Children linked to most recent parent row | ⏳ |
| TC-10-02-07 | Import with invalid rows logs errors | Row with missing required column | 1. Run import | Job completes; error rows listed in import log; valid rows still processed | ⏳ |

---

## TC-10-03 — Real-time Import Notification

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-10-03-01 | Import notification via Turbo Stream | User on uploads page | 1. Trigger import job<br>2. Wait for job completion | Turbo Stream pushes notification message to user without page reload | ⏳ |
| TC-10-03-02 | Action Cable channel connected on uploads page | User visits `/uploads` | 1. Open browser console<br>2. Check WebSocket connections | `ImportNotificationsChannel` subscription active | ⏳ |
| TC-10-03-03 | Notification shows success count | Import succeeds | 1. After job completes | Notification: "X products imported successfully" | ⏳ |
| TC-10-03-04 | Notification shows error count | Import has errors | 1. After job completes with some errors | Notification mentions number of failed rows | ⏳ |
