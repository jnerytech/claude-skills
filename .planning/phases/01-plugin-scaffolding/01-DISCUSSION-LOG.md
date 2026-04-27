# Phase 1: Plugin Scaffolding - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in 01-CONTEXT.md — this log preserves the discussion record.

**Date:** 2026-04-26
**Phase:** 01-plugin-scaffolding
**Mode:** discuss (default)
**Areas discussed:** Install delivery, settings.local.json delivery

---

## Gray Areas Presented

1. Install delivery — SETUP-04: script vs plugin install vs manual copy
2. Placeholder depth — SETUP-02: stub content level
3. docs/index.md format — SETUP-03: structure for skill-create to read
4. settings.local.json delivery — SETUP-05: example file vs gitignored vs README only

**User selected:** Install delivery, settings.local.json delivery

---

## Discussion: Install Delivery

| Question | Options | Selected |
|----------|---------|----------|
| How should users install locally? | Plugin install only / Script + docs / Manual copy + docs | Plugin install only |
| Where should install instructions live? | README.md / INSTALL.md / CLAUDE.md only | README.md |
| Continue or move on? | Next area / More questions | Next area |

**Decisions locked:**
- No helper script — `/plugin install` is the mechanism
- README.md "Getting Started" section carries the instructions

---

## Discussion: settings.local.json Delivery

| Question | Options | Selected |
|----------|---------|----------|
| How to deliver the template? | .example file / gitignored actual file / README inline | settings.local.json.example |
| Permission scope? | Minimal (required only) / Extended (common additions) / You decide | Extended — common additions |
| Continue or ready for context? | Ready for context / More questions | Ready for context |

**Decisions locked:**
- `settings.local.json.example` committed to repo
- Extended scope: Write(.claude/**), Write(~/.claude/**), Bash(mkdir:**), Bash(cp:**)

---

## Areas at Claude's Discretion

- Placeholder SKILL.md content depth (bare stub sufficient for Phase 1)
- docs/index.md internal format (planner designs for skill-create readability)
- AskUserQuestion 4-option constraint notation location

---

## Deferred Ideas

None surfaced during discussion.
