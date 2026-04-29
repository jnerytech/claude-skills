---
phase: 04-workspace-creator-skill
plan: "01"
subsystem: skills/workspace-create
tags: [skill, workspace, scaffold, interview, claude-md, template]
dependency_graph:
  requires: []
  provides:
    - skills/workspace-create/SKILL.md (complete 9-stage instruction body)
    - skills/workspace-create/templates/CLAUDE.md.template (runtime template with 6 markers)
  affects:
    - .claude-plugin/plugin.json (references workspace-create skill)
tech_stack:
  added: []
  patterns:
    - chat-freeform interview (Q1-Q5, variable-length inputs)
    - 4-backtick scaffold plan preview fence
    - marker substitution via {{DOUBLE_BRACE}} template pattern
    - validate -> mkdir -> Write sequence (carry-forward from Phase 3)
    - $(pwd)-based WORKSPACE_ROOT resolution (CWD-relative, not global)
key_files:
  created:
    - skills/workspace-create/templates/CLAUDE.md.template
  modified:
    - skills/workspace-create/SKILL.md
decisions:
  - "D-01: allowed-tools amended to [Read, Write, Bash] — Stage 7 must Read ${CLAUDE_SKILL_DIR}/templates/CLAUDE.md.template; stub comment on line 17 stated this was always the design intent"
  - "Workspace root uses $(pwd)/<validated-name> — CWD-relative, never $USERPROFILE or ~ (Phase 4 creates local workspaces, not global paths)"
  - "Chat-freeform interview for all Q1-Q5 — AskUserQuestion 4-option limit prevents capturing variable-length repo names and purposes"
  - "Separate CLAUDE.md.template file (Approach A) chosen over inline generation (Approach B) — template stays maintainable independently of SKILL.md"
metrics:
  duration: "~15 minutes"
  completed: "2026-04-29"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 1
  files_deleted: 1
---

# Phase 4 Plan 01: Workspace Creator Skill Summary

9-stage workspace scaffolder skill with chat-freeform interview, atomic mkdir batch, 7 README writes, CLAUDE.md marker substitution from a Read-loaded template, and 12-item final-checks gate.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create CLAUDE.md.template with all 6 markers | 0f594b6 | skills/workspace-create/templates/CLAUDE.md.template (created), .gitkeep (deleted) |
| 2 | Write workspace-create SKILL.md body and amend allowed-tools | 9f3b1e0 | skills/workspace-create/SKILL.md (replaced placeholder with 228-line body) |

## Deliverables

### skills/workspace-create/templates/CLAUDE.md.template

New file. 37 lines. Contains all 6 required markers:
- `{{WORKSPACE_NAME}}` — from interview Q1 (required, re-asked if blank)
- `{{WORKSPACE_GOAL}}` — from interview Q4 (required, re-asked if blank)
- `{{CREATED_DATE}}` — from Bash `date +%Y-%m-%d`
- `{{REPO_MAP}}` — table rows built from Q2+Q3 answers; fallback: "No repos specified"
- `{{STACK}}` — from Q5; fallback: "Not specified"
- `{{CONVENTIONS}}` — derived from stack + goal; fallback: "Follow standard conventions for the stack"

Static sections (not markers): Directory Map (7 subdirectory rows hardcoded), Session Conventions.

### skills/workspace-create/SKILL.md

228 lines. Replaces the 24-line placeholder comment stub. Frontmatter amended per D-01 to add Read to allowed-tools.

Stages:
1. Check for workspace name hint in `$ARGUMENTS`
2. Chat-freeform interview Q1-Q5 with inline name validation (Bash regex gate)
3. Scaffold plan preview (4-backtick fence) + chat confirmation gate
4. Existing workspace detection with warn+confirm
5. Atomic mkdir -p batch (9 directories)
6. 7 README.md writes (one per .workspace/ subdir)
7. Read template → replace 6 markers → wc -l guard (< 195) → zero-{{ scan → Write CLAUDE.md
8. Write workspace-local .claude/settings.local.json
9. Confirmation message

Includes: worked example (end-to-end my-apis walkthrough), 12-item final checks list.

## Deviations from Plan

### Plan-Time Deviations Honored

**D-01: Frontmatter `allowed-tools` amended to add `Read`**
- Stub frontmatter: `allowed-tools: [Write, Bash]`
- Implemented: `allowed-tools: [Read, Write, Bash]`
- Reason: Stage 7 of the skill must Read `${CLAUDE_SKILL_DIR}/templates/CLAUDE.md.template` for marker substitution. The stub's own comment on line 17 stated "Load ... CLAUDE.md.template" — Read was always the design intent.
- Pre-documented in the plan as Deviation D-01 — not an executor-time surprise.

### Auto-Fixed Issues

None — plan executed exactly as written.

## Requirements Addressed

| Req ID | Description | Status |
|--------|-------------|--------|
| WORK-01 | User invokes /workspace-create and is guided through an interview | Addressed in Stages 1-3 |
| WORK-02 | Interview captures workspace name, repos, per-repo purpose, goal | Addressed in Stage 2 Q1-Q5 |
| WORK-03 | Scaffolds .workspace/ with refs/, docs/, logs/, scratch/, context/, outputs/, sessions/ | Addressed in Stages 5-6 |
| WORK-04 | Creates .claude/ and .vscode/ directories at workspace root | Addressed in Stage 5 (mkdir batch) + Stage 8 (settings file) |
| WORK-05 | Generates fully populated CLAUDE.md — no stubs, no unreplaced markers | Addressed in Stage 7 (marker replacement, zero-{{ scan, wc -l guard) |
| WORK-06 | Creates one-line README in each .workspace/ subdir | Addressed in Stage 6 (7 README.md writes) |

## Known Stubs

None. The skill body contains complete instructions for all stages. The template file contains markers that are replaced at runtime (by design — they are not output stubs). The generated CLAUDE.md is verified by the skill to contain zero `{{` patterns before being written.

## Threat Flags

No new security-relevant surface introduced beyond what was in the plan's threat model.

Threat mitigations confirmed present in SKILL.md:
- T-04-01: Name validation `^[a-z][a-z0-9-]*$` with path traversal rejection — Stage 2 Q1 Bash gate
- T-04-02: Existing workspace detection with warn+confirm — Stage 4
- T-04-03: Zero `{{` marker scan before Write — Stage 7 final step
- T-04-04: WORKSPACE_ROOT resolved via `$(pwd)/<validated-name>` — never `$USERPROFILE` or `~`

## Self-Check

### Files exist:

```
test -f skills/workspace-create/templates/CLAUDE.md.template → EXISTS
test -f skills/workspace-create/SKILL.md → EXISTS
```

### Commits exist:

```
0f594b6 feat(04-01): create CLAUDE.md.template with 6 interview markers
9f3b1e0 feat(04-01): implement workspace-create SKILL.md body and add Read tool
```

## Self-Check: PASSED
