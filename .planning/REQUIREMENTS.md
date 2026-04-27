# Requirements — Claude Code Skills Plugin

**Project:** Claude Code Skills Plugin
**Status:** v1 scoped
**Last updated:** 2026-04-26

---

## v1 Requirements

### Plugin Scaffolding

- [x] **SETUP-01**: Repository has valid `.claude-plugin/plugin.json` manifest with `name`, `description`, and `author` fields enabling `/plugin install` *(Phase 1)*
- [x] **SETUP-02**: Skills directory structure exists at `skills/improve-prompt/`, `skills/skill-create/`, and `skills/workspace-create/` with placeholder SKILL.md entrypoints *(Phase 1)*
- [x] **SETUP-03**: `docs/` folder exists at repo root with `docs/index.md` explaining which Claude Code documentation files to download and where to place them *(Phase 1)*
- [x] **SETUP-04**: Install/symlink script or documented instructions for deploying plugin skills to the Claude Code plugin cache or `~/.claude/skills/` *(Phase 1)*
- [x] **SETUP-05**: `settings.local.json` template pre-configured with `Write(.claude/**)` and `Write(~/.claude/**)` permission allows to work around v2.1.79+ permission regression *(Phase 1)*

### Prompt Improvement

- [ ] **PROMPT-01**: User can invoke `/improve-prompt <rough-prompt>` and receive a rewritten version in chat (no file writes, no external dependencies)
- [ ] **PROMPT-02**: Skill rewrites input optimizing for all four dimensions: clarity/specificity, context richness, structure, and scope/verification criteria
- [ ] **PROMPT-03**: Output shows original prompt and improved prompt side by side in chat
- [ ] **PROMPT-04**: Output includes "what changed" annotation explaining each material improvement made
- [ ] **PROMPT-05**: Improved prompt injects Claude Code-specific idioms where appropriate (`@file` references, explicit verification asks, scope bounds)

### Skill Creator

- [ ] **SKILL-01**: User can invoke `/skill-create` and describe the skill they want to build (freeform or via argument)
- [ ] **SKILL-02**: Skill reads `${CLAUDE_SKILL_DIR}/docs/` before generating to ground output in locally available Claude Code documentation
- [ ] **SKILL-03**: Skill interviews user with 5-6 targeted questions, each offering proposed answers for the user to react to (not blank questions)
- [ ] **SKILL-04**: Generated SKILL.md is shown to user for review and confirmation before any file is written
- [ ] **SKILL-05**: Confirmed skill is written to exactly `~/.claude/skills/<name>/SKILL.md` (global scope, available in all sessions)

### Workspace Creator

- [ ] **WORK-01**: User can invoke `/workspace-create` to start a guided workspace setup interview
- [ ] **WORK-02**: Skill interviews user capturing: workspace name, list of repos to include, per-repo purpose, and overall workspace goal
- [ ] **WORK-03**: Skill scaffolds full `.workspace/` directory structure: `refs/`, `docs/`, `logs/`, `scratch/`, `context/`, `outputs/`, `sessions/`
- [ ] **WORK-04**: Skill creates `.claude/` and `.vscode/` directories at workspace root alongside `.workspace/`
- [ ] **WORK-05**: Skill generates a fully populated `CLAUDE.md` at workspace root derived from interview answers — no stubs, no unfilled placeholders
- [ ] **WORK-06**: Skill creates a one-line README in each `.workspace/` subdirectory explaining its purpose

---

## v2 Requirements

*(Deferred — expected by users but not in v1 scope)*

- Multiple prompt rewrite variants (different tones/styles) — adds decision fatigue in v1
- Prompt scoring or grading — no meaningful rubric defined yet
- Skill creator automated test runner — recursive invocation risk, high complexity
- Skill versioning / update mechanism — `~/.claude/skills/` is sufficient for v1
- MCP server configuration generation — out of v1 scope per PROJECT.md

---

## Out of Scope

- **MCP server integration** — Skills run inline; no MCP server needed for any of the three deliverables
- **Cloud sync of generated skills** — Global `~/.claude/skills/` covers the use case; sync is a separate product concern
- **Prompt injection protection** — User-supplied arguments are treated as bounded data by the skills platform; no additional hardening needed in v1
- **Marketplace submission** — Plugin packaging is in scope; actual submission to Anthropic marketplace is not a v1 deliverable

---

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| SETUP-01 | Phase 1 | Complete |
| SETUP-02 | Phase 1 | Complete |
| SETUP-03 | Phase 1 | Complete |
| SETUP-04 | Phase 1 | Complete |
| SETUP-05 | Phase 1 | Complete |
| PROMPT-01 | Phase 2 | Pending |
| PROMPT-02 | Phase 2 | Pending |
| PROMPT-03 | Phase 2 | Pending |
| PROMPT-04 | Phase 2 | Pending |
| PROMPT-05 | Phase 2 | Pending |
| SKILL-01 | Phase 3 | Pending |
| SKILL-02 | Phase 3 | Pending |
| SKILL-03 | Phase 3 | Pending |
| SKILL-04 | Phase 3 | Pending |
| SKILL-05 | Phase 3 | Pending |
| WORK-01 | Phase 4 | Pending |
| WORK-02 | Phase 4 | Pending |
| WORK-03 | Phase 4 | Pending |
| WORK-04 | Phase 4 | Pending |
| WORK-05 | Phase 4 | Pending |
| WORK-06 | Phase 4 | Pending |
