# TC-05 — Customers & Logistic Companies
**Module:** Customers, Logistic Companies  
**Based on:** EPIC-03

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Pass |
| ❌ | Fail |
| ⏳ | Not Executed |

---

## TC-05-01 — Customer CRUD

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-05-01-01 | Create customer | Admin logged in | 1. Navigate to `/customers/new`<br>2. Fill name, telephone, address<br>3. Submit | Customer created; appears in list | ⏳ |
| TC-05-01-02 | Duplicate customer name rejected | Customer with same name | 1. Submit with duplicate name | 422; validation error | ⏳ |
| TC-05-01-03 | Edit customer | Customer exists | 1. Edit name/telephone<br>2. Submit | Customer updated | ⏳ |
| TC-05-01-04 | Delete customer with no orders | Customer has no orders | 1. Delete customer | Customer removed | ⏳ |
| TC-05-01-05 | Delete customer linked to orders | Customer has orders | 1. Attempt delete | 409 error; customer preserved | ⏳ |
| TC-05-01-06 | Customer appears in order form typeahead | Customer exists | 1. Open `/orders/new`<br>2. Type customer name | Customer appears in Tom Select dropdown | ⏳ |
| TC-05-01-07 | Customer address autofills in order | Customer with address | 1. Select customer in order form | Address field auto-populated | ⏳ |
| TC-05-01-08 | Search customers by name | Multiple customers | 1. Use search bar | Matching customers returned | ⏳ |

---

## TC-05-02 — Logistic Company Management

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-05-02-01 | Create logistic company | Admin logged in | 1. Navigate to `/logistic_companies/new`<br>2. Enter name, fee<br>3. Submit | Logistic company created | ⏳ |
| TC-05-02-02 | Edit logistic company | Company exists | 1. Edit name/fee<br>2. Submit | Company updated | ⏳ |
| TC-05-02-03 | Assign logistic company to customer | Customer + company exist | 1. Edit customer<br>2. Select logistic company<br>3. Submit | Customer `logistic_company_id` saved | ⏳ |
| TC-05-02-04 | Logistic company autofills from customer in order | Customer has default logistic company | 1. Select customer in order form | Logistic company field auto-populated | ⏳ |
| TC-05-02-05 | Logistic fee included in order total | Order with logistic company | 1. Create order with logistic company | Logistic fee added to grand total breakdown | ⏳ |
| TC-05-02-06 | Delete logistic company | Company not used | 1. Delete company | Company removed | ⏳ |
