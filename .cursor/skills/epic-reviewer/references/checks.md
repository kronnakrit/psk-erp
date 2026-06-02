# Review Checks

Apply every check below to each story. Severity levels: **Critical**, **Major**, **Minor**.

---

## AC Quality

| Severity | Check |
|----------|-------|
| Critical | Every story has at least one **unhappy-path** AC (validation failure, 403, 404, 422, etc.) |
| Critical | Every AC uses strict BDD format: **Given / When / Then** — no prose-only criteria |
| Critical | Every "Then" clause is verifiable: HTTP status, DB change, rendered element, flash message, or redirect — not "user sees" or "it works" |
| Major | No AC references a field, button, or route that could not have been observed in the running app (flag as `[UNGROUNDED]`) |
| Major | PSK ERP status codes used correctly: `200`, `201`, `204`, `302`, `401`, `403`, `404`, `409`, `422` — no invented codes |
| Minor | No AC contains vague language: "fast", "user-friendly", "good UX", "properly", "correctly" |

---

## Task Quality

| Severity | Check |
|----------|-------|
| Critical | Every feature task has a corresponding `Write RSpec spec for [thing]` task in the same story |
| Critical | If any story touches the database schema, the first task is a migration task |
| Major | No single task is estimated to exceed ~4 hours (flag tasks that bundle multiple concerns) |
| Major | API endpoint tasks include: route, HTTP verb, request params, response shape, and HTTP status |
| Major | Frontend tasks specify the view file and the Turbo/Stimulus interaction pattern |
| Minor | Task IDs follow the format `T-XX-YY-ZZ` (epic, story, task number) with no gaps |

---

## Structure & Format

| Severity | Check |
|----------|-------|
| Critical | Story IDs follow `STORY-XX-YY` and are sequential with no gaps |
| Critical | Epic status is one of: `🔴 Not Started`, `🟡 In Progress`, `🟢 Completed` |
| Major | Legend block is present and matches the canonical symbols from the output format |
| Major | Every story has `**Status:**`, `**Description:**`, `**User Perspective:**`, `**Acceptance Criteria:**`, `**Edge Cases:**`, and a task table |
| Minor | No `[REQUIRES CLARIFICATION: ...]` items remain unresolved |
| Minor | Epic `**Goal:**` is a single sentence ending with a measurable outcome |

---

## Completeness

| Severity | Check |
|----------|-------|
| Major | At least 2 edge cases listed per story |
| Minor | No story description is identical to another (signals copy-paste without customization) |
