# PSK ERP — Cursor Agent Guide

This repo uses **Cursor** conventions under `.cursor/`. Content was migrated from `.agents/` (Copilot-style layout) and `.github/instructions` + `.github/agents` (GitHub Copilot).

## Layout

| Path | Purpose |
|------|---------|
| [.cursor/rules/](.cursor/rules/) | Project rules (`.mdc`) — auto-attached by file glob |
| [.cursor/skills/](.cursor/skills/) | Agent skills (`SKILL.md`) — loaded when relevant or invoked by name |

## Rules (file-scoped)

| Rule | Applies to |
|------|------------|
| `rails.mdc` | `**/*.rb`, `**/*.erb`, `routes.rb`, `Gemfile` |
| `ruby-on-rails.mdc` | `**/*.rb` |
| `project-management.mdc` | `project_management/**/*.md` |

## Skills (workflows)

| Skill | When to use |
|-------|-------------|
| `agile-po` | Epics, stories, acceptance criteria, BDD |
| `epic-implementor` | Implement stories from `project_management/EPIC-XX/` |
| `epic-reviewer` | Audit epics and `stories.md` |
| `e2e-qa` | Capybara system specs from `testcases/TC-XX` |
| `fix-ui` | UI audit/fix via Chrome MCP + Tailwind |
| `rails-expert` | Rails 7+ / Hotwire / Sidekiq / RSpec patterns |
| `quality-assurance` | Testing strategy and validation gates |
| `caveman` / `caveman-commit` | Compressed comms / commit messages |
| `ui-ux-pro-max` | UI/UX design intelligence and data |

Invoke explicitly: e.g. *"use epic-implementor on EPIC-01"* or *"fix ui http://localhost:3000/users"*.

## Legacy folders (kept for reference)

- `.agents/` — previous Copilot agent mirror (prefer `.cursor/` for Cursor)
- `.github/instructions/`, `.github/agents/`, `.github/prompts/` — GitHub Copilot sources (CI stays in `.github/workflows/`)

When editing skills, update **`.cursor/skills/`** so Cursor picks up changes.
