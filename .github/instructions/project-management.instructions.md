---
description: "Use when creating or editing files in project_management/. Enforces PSK ERP epic and story conventions: legend symbols, status values, story ID format, task ID format, and BDD acceptance criteria structure."
applyTo: "project_management/**/*.md"
---

# Project Management Conventions

## Status Symbols

Always use exactly these symbols — no alternatives, no plain text:

| Symbol           | Meaning                  |
| ---------------- | ------------------------ |
| `🔴 Not Started` | Work has not begun       |
| `🟡 In Progress` | Actively being worked on |
| `🟢 Completed`   | Done and verified        |

Task checkboxes in task tables:

| Marker | Meaning     |
| ------ | ----------- |
| `[ ]`  | Not started |
| `[~]`  | In progress |
| `[x]`  | Completed   |

## Naming & ID Formats

- Epic directories: `EPIC-XX/` where `XX` is zero-padded (e.g. `EPIC-01`, `EPIC-12`)
- Story IDs: `STORY-XX-YY` — sequential, no gaps (e.g. `STORY-19-01`, `STORY-19-02`)
- Task IDs: `T-XX-YY-ZZ` — matches its parent story (e.g. `T-19-01-01`)
- AC IDs: `AC-01`, `AC-02` — reset per story

## Required Sections in stories.md

Every `stories.md` must have at its top level:

1. `# EPIC-XX — [Title]`
2. `**Phase:**`, `**Status:**`, `**Goal:**`
3. `## Legend` block with the full symbol table
4. `## Stories` section

Every story block must contain:

1. `### STORY-XX-YY — [Title]`
2. `**Status:**`, `**Description:**`, `**User Perspective:**`
3. `**Acceptance Criteria:**` table (Given / When / Then columns)
4. `**Edge Cases:**` list (minimum 2 items)
5. Task table with `#`, `Task`, `Status` columns

## BDD Acceptance Criteria

- Column headers must be exactly: `#`, `Given`, `When`, `Then`
- Every "Then" must be verifiable (HTTP status, DB state, rendered element, flash message, or redirect) — never "user sees the page" or "it works"
- At least one AC per story must cover an unhappy path (validation error, 403, 404, or 422)

## epics.md

When adding a row to `project_management/epics.md`, use this column order:
`| EPIC-XX | [Title] | [Phase] | 🔴 Not Started |`

# Default Credentials for Browser Inspection

username: admin@psk.com
password: Admin@12345!
