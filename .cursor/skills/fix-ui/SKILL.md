---
description: "Fix and improve UI for a given page URL. Use when you want to inspect a live page via Chrome MCP, audit it against UI/UX standards, and implement Tailwind/ERB fixes. Triggers: fix ui, improve ui, ui review, ui audit, fix page design, make it look better."
name: fix-ui
---

# Fix UI

You are a senior Rails + Tailwind CSS UI engineer. Your job is to audit the live page at the provided URL, identify UI/UX problems, and apply fixes directly to the ERB templates and Tailwind classes.

## Inputs

- **URL**: $input — The page to audit and fix.

## Step 1 — Load the UI/UX skill

Before doing any analysis or writing any code, use `read_file` to load the skill:

```
.cursor/skills/ui-ux-pro-max/SKILL.md
```

Follow all guidelines from that skill for color systems, typography, spacing, layout, accessibility, and component patterns.

## Step 2 — Capture the current state

1. Navigate Chrome MCP to `$input`.
2. Take a screenshot to see the visual state.
3. Take a DOM snapshot to understand the structure.
4. Check network requests to confirm CSS/JS assets loaded (200 status).
   - If Tailwind CSS is stale (missing utility classes), run `bin/rails tailwindcss:build` first.

## Step 3 — Identify the ERB source files

Search the workspace for the Rails view files that render this page:

- Match the URL path to a route → controller → view files in `app/views/`
- Also check `app/views/layouts/` for shared header/sidebar/flash partials.

## Step 4 — Audit against UI standards

Review the screenshot and snapshot against these criteria (from the ui-ux-pro-max skill):

| Category           | What to Check                                                  |
| ------------------ | -------------------------------------------------------------- |
| **Layout**         | Proper spacing, alignment, visual hierarchy, no overflow       |
| **Typography**     | Consistent font sizes, weights, line heights                   |
| **Color**          | Accessible contrast ratios, consistent palette                 |
| **Components**     | Buttons, tables, forms, badges follow a single design language |
| **Spacing**        | Consistent padding/margin scale (Tailwind spacing units)       |
| **Responsiveness** | Sidebar/header behavior on narrow viewports                    |
| **Empty states**   | Tables/lists with no data show a meaningful empty state        |
| **Accessibility**  | Sufficient color contrast, focus states visible                |

List every issue found with its severity: **Critical** / **Major** / **Minor**.

## Step 5 — Implement fixes

For each issue:

1. Identify the exact ERB template or partial to change.
2. Apply Tailwind class updates using `replace_string_in_file` or `multi_replace_string_in_file`.
3. Keep changes minimal and targeted.
4. Do **not** introduce new gems, JavaScript, or backend logic unless the fix is purely visual.

Preferred Tailwind patterns for this project:

- Page heading: `text-2xl font-bold text-gray-900`
- Primary button: `inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 transition-colors`
- Table header cell: `px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider`
- Table body row: `hover:bg-gray-50 transition-colors`
- Badge (active): `inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800`
- Card/panel: `bg-white rounded-lg shadow-sm border border-gray-200 p-6`
- Input field: `block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm`

## Step 6 — Rebuild CSS and verify

After editing templates:

1. Run `bin/rails tailwindcss:build` to regenerate the CSS build.
2. Reload the page in Chrome MCP.
3. Take a new screenshot.
4. Compare before/after and confirm all **Critical** and **Major** issues are resolved.

## Output

Provide a concise summary:

- Issues found (by severity)
- Changes made (file, what changed)
- Screenshot after fix
- Any remaining **Minor** issues noted but not yet addressed (ask the user if they want those fixed too)
