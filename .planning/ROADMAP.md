# Roadmap: Claude Code Skills Plugin

## Overview

Three Claude Code slash-command skills packaged as a single installable plugin. The build proceeds in dependency order: scaffolding first to validate plugin packaging, then /improve-prompt (zero filesystem dependencies), then /skill-create (exercises global write paths), then /workspace-create (heaviest filesystem surface). Every phase is independently verifiable — no "big bang" delivery.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Plugin Scaffolding** - Repo structure, plugin manifest, docs index, and permission workaround in place
- [ ] **Phase 2: Prompt Improvement Skill** - /improve-prompt skill rewrites rough prompts in chat with no file writes
- [ ] **Phase 3: Skill Creator Skill** - /skill-create interviews user and writes a new skill globally to ~/.claude/skills/
- [ ] **Phase 4: Workspace Creator Skill** - /workspace-create guides full workspace setup with populated CLAUDE.md

## Phase Details

### Phase 1: Plugin Scaffolding
**Goal**: The plugin is installable and the repo structure is ready for skill development
**Depends on**: Nothing (first phase)
**Requirements**: SETUP-01, SETUP-02, SETUP-03, SETUP-04, SETUP-05
**Success Criteria** (what must be TRUE):
  1. User can run `/plugin install` against the repo without errors and the plugin appears in the plugin cache
  2. `skills/improve-prompt/`, `skills/skill-create/`, and `skills/workspace-create/` directories each exist with a placeholder SKILL.md
  3. `docs/index.md` exists and lists exactly which Claude Code documentation files to download and where to place them
  4. Install instructions exist and document how to deploy skills to `~/.claude/skills/`
  5. `settings.local.json` template exists with `Write(.claude/**)` and `Write(~/.claude/**)` allow rules so the permission regression in v2.1.79+ does not block skill writes
**Plans**: 3 plans

Plans:
- [ ] 01-01-PLAN.md — Plugin manifest, install docs, permissions template (.claude-plugin/plugin.json, README.md, settings.local.json.example, .gitignore)
- [ ] 01-02-PLAN.md — Skill stub directories with valid SKILL.md placeholders and supporting directories (skills/*/SKILL.md, references/.gitkeep, templates/.gitkeep)
- [ ] 01-03-PLAN.md — Documentation index for skill-create's on-demand doc loading (docs/index.md)

### Phase 2: Prompt Improvement Skill
**Goal**: Users can invoke /improve-prompt with a rough prompt and receive a clearly improved version in chat
**Depends on**: Phase 1
**Requirements**: PROMPT-01, PROMPT-02, PROMPT-03, PROMPT-04, PROMPT-05
**Success Criteria** (what must be TRUE):
  1. User invokes `/improve-prompt <rough-prompt>` and receives a rewritten prompt in chat — no files written, no external calls made
  2. The rewritten prompt is observably improved across all four dimensions: clarity/specificity, context richness, structure, and scope/verification criteria
  3. Chat output shows the original prompt and the improved prompt side by side
  4. Chat output includes a "what changed" annotation explaining each material improvement
  5. Where appropriate, the improved prompt contains Claude Code-specific idioms such as `@file` references, explicit verification asks, and scope bounds
**Plans**: TBD

### Phase 3: Skill Creator Skill
**Goal**: Users can describe a skill they want built, answer targeted interview questions, and have the generated SKILL.md written globally
**Depends on**: Phase 2
**Requirements**: SKILL-01, SKILL-02, SKILL-03, SKILL-04, SKILL-05
**Success Criteria** (what must be TRUE):
  1. User invokes `/skill-create` (with or without an argument) and can describe the skill they want in freeform text
  2. Before generating, the skill reads `${CLAUDE_SKILL_DIR}/docs/` and grounds its output in the locally available Claude Code documentation
  3. User receives 5-6 targeted interview questions, each presenting proposed answers to react to rather than blank fields to fill in
  4. Generated SKILL.md is displayed for review and confirmation before any file is written
  5. After confirmation, the skill is written to exactly `~/.claude/skills/<name>/SKILL.md` and is available in all future Claude Code sessions
**Plans**: TBD

### Phase 4: Workspace Creator Skill
**Goal**: Users can run a guided interview and receive a fully scaffolded workspace with a populated CLAUDE.md derived from their answers
**Depends on**: Phase 3
**Requirements**: WORK-01, WORK-02, WORK-03, WORK-04, WORK-05, WORK-06
**Success Criteria** (what must be TRUE):
  1. User invokes `/workspace-create` and is guided through an interview capturing workspace name, repos to include, per-repo purpose, and overall workspace goal
  2. The full `.workspace/` directory structure is created: `refs/`, `docs/`, `logs/`, `scratch/`, `context/`, `outputs/`, `sessions/`
  3. `.claude/` and `.vscode/` directories are created at workspace root alongside `.workspace/`
  4. `CLAUDE.md` is created at workspace root with all sections fully populated from interview answers — no stubs, no unfilled placeholders
  5. Each `.workspace/` subdirectory contains a one-line README explaining its purpose
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Plugin Scaffolding | 0/3 | Not started | - |
| 2. Prompt Improvement Skill | 0/? | Not started | - |
| 3. Skill Creator Skill | 0/? | Not started | - |
| 4. Workspace Creator Skill | 0/? | Not started | - |
