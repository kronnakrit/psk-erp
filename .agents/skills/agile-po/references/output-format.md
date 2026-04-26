# Output Format Reference

## Markdown File Structure

Produce a single Markdown file with this exact structure:

```markdown
# EPIC-XX — [Epic Title]

**Phase:** XX
**Status:** 🔴 Not Started
**Goal:** [One sentence: what is the end state when this epic is complete?]

---

## Legend

| Symbol         | Meaning                  |
| -------------- | ------------------------ |
| 🔴 Not Started | Work has not begun       |
| 🟡 In Progress | Actively being worked on |
| 🟢 Completed   | Done and verified        |
| `[ ]`          | Task not started         |
| `[~]`          | Task in progress         |
| `[x]`          | Task completed           |

---

## Stories

### STORY-XX-01 — [Story Title]

**Status:** 🔴 Not Started
**Description:** [1–2 sentence summary of what this story delivers]

**User Perspective:**
As a [Role], I want to [Action], so that [Value].

**Acceptance Criteria:**

| #     | Given     | When     | Then                 |
| ----- | --------- | -------- | -------------------- |
| AC-01 | [context] | [action] | [verifiable outcome] |
| AC-02 | ...       | ...      | ...                  |

**Edge Cases:**

- [Edge case 1]
- [Edge case 2]

| #          | Task                      | Status |
| ---------- | ------------------------- | ------ |
| T-XX-01-01 | [Granular developer task] | `[ ]`  |
| T-XX-01-02 | [Another task]            | `[ ]`  |
```

---

## Acceptance Criteria Rules

- Use strict BDD: **Given** [precondition], **When** [actor does X], **Then** [verifiable outcome].
- "Verifiable" means: HTTP status code, database change, rendered element, flash message, redirect destination — not "it works" or "user sees the page".
- Always include at least one **unhappy-path** AC (validation failure, 403, not found, etc.) per story.
- Use the PSK ERP status codes: `200`, `201`, `204`, `302`, `401`, `403`, `404`, `409`, `422`.

---

## Task Rules

- Tasks must be granular enough for a single developer to complete in isolation (1–4 hours each).
- Every feature task must have a corresponding `Write RSpec spec for [thing]` task.
- Frontend tasks must specify the view file and the Turbo/Stimulus interaction pattern where applicable.
- API endpoint tasks must include: route, HTTP verb, request params, response shape, and HTTP status.
- If a migration is needed, it is always the first task in the story.
