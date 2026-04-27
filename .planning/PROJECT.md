# Claude Code Skills Plugin

## What This Is

A collection of three Claude Code slash-command skills that improve day-to-day workflow: a prompt rewriter that upgrades rough input into clear, structured prompts; a skill generator that interviews the user and produces new skills from local documentation; and a guided workspace scaffolder that creates an opinionated, isolation-first project structure with a fully populated CLAUDE.md.

## Core Value

Three skills that save time on the three most repeated setup and framing tasks in a Claude Code session — prompt quality, skill authoring, and workspace setup.

## Requirements

### Validated

- [x] **Plugin scaffolding** — Plugin manifest, README, permissions template, skill stubs, and docs index all in place. Validated in Phase 1 (2026-04-27)

### Active

- [ ] **Prompt improvement skill** — slash command that takes the user's rough prompt and rewrites it optimizing for clarity/specificity, context richness, and structure; outputs the improved version in chat
- [ ] **Skill creator skill** — slash command where user describes a desired skill; Claude reads pre-downloaded docs from `docs/` folder inside the skill directory, interviews the user with targeted questions, then generates the skill file saved globally to `~/.claude/skills/`
- [ ] **Workspace creator skill** — full guided setup slash command that asks workspace name, repos to include, and purpose; scaffolds complete workspace structure (`.workspace/refs/`, `.workspace/docs/`, `.workspace/logs/`, `.workspace/scratch/`, `.workspace/context/`, `.workspace/outputs/`, `.workspace/sessions/`, `.claude/`, `.vscode/`) with a populated CLAUDE.md at the workspace root

### Out of Scope

- MCP server integration — not needed for v1, skills run inline
- Sync / cloud storage of generated skills — global `~/.claude/skills/` is sufficient
- Skill versioning / update mechanism — out of v1 scope

## Context

- Skills are Claude Code slash commands defined as Markdown files in a `skills/` directory
- Claude Code documentation is pre-downloaded by the user to a `docs/` folder inside this repo — the skill creator reads from there, no network fetch required
- Workspace structure follows an opinionated isolation convention: user artifacts live inside `.workspace/`, repos live as named top-level dirs, `.claude/` and `.vscode/` are tooling config outside `.workspace/`
- Skills saved to `~/.claude/skills/` are available globally across all Claude Code sessions
- The CLAUDE.md at workspace root should carry permanent context (workspace purpose, repo map, session conventions) derived from the guided setup interview

## Constraints

- **Format**: All three deliverables are Claude Code skill files (Markdown with `<skill>` structure)
- **Docs**: Skill creator must reference local `docs/` folder only — no live web fetches
- **Scope**: Workspace creator must generate populated CLAUDE.md content from interview answers, not leave stubs

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Skills saved globally (`~/.claude/skills/`) | Available across all sessions without per-project setup | — Pending |
| Docs pre-downloaded locally | Avoids network dependency, works offline | — Pending |
| Workspace creator does full guided interview | User gets a real CLAUDE.md they can use immediately, not a template to fill in | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-27 — Phase 1 complete*
