# Report Format

Produce the findings report in this exact structure:

```markdown
## Epic Review — EPIC-XX

**File:** project_management/EPIC-XX/stories.md
**Reviewed:** [today's date]
**Stories reviewed:** N

---

### STORY-XX-01 — [Story Title]

#### 🔴 Critical

| Ref    | Check                        | Detail                                      |
| ------ | ---------------------------- | ------------------------------------------- |
| AC-03  | Missing unhappy-path AC      | No AC covers the 422 validation failure path |
| T-01-03 | Missing RSpec task           | Feature task T-01-03 has no corresponding spec task |

#### 🟠 Major

| Ref    | Check                        | Detail                                      |
| ------ | ---------------------------- | ------------------------------------------- |
| T-01-05 | Over-scoped task             | "Implement order search and filtering" bundles 2+ concerns — split into separate tasks |

#### 🟡 Minor

| Ref    | Check                        | Detail                                      |
| ------ | ---------------------------- | ------------------------------------------- |
| AC-01  | Vague language               | "Then the user sees the results correctly" is not verifiable |

---

### STORY-XX-02 — [Story Title]

✅ No issues found.

---

## Summary

| Severity | Count |
| -------- | ----- |
| 🔴 Critical | N |
| 🟠 Major    | N |
| 🟡 Minor    | N |
| **Total**   | **N** |
```

## Rules

- Use `✅ No issues found.` only when all checks pass for that story.
- Always include the `Ref` column — use the exact AC or task ID from the file.
- `Detail` must be specific: quote the offending text or state exactly what is absent.
- Do not suggest fixes in the report — report findings only.
