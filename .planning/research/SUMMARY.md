# Project Research Summary

**Project:** Claude Code Skills Plugin
**Domain:** Claude Code skill authoring (SKILL.md slash-command plugins)
**Researched:** 2026-04-26
**Confidence:** HIGH

## Executive Summary

This project builds three Claude Code skills packaged as a plugin: a prompt rewriter (`/improve-prompt`), a skill generator (`/skill-create`), and a workspace scaffolder (`/workspace-create`). Skills are directory-based Markdown files using YAML frontmatter — there is no `<skill>` XML structure. The actual format is `skills/<name>/SKILL.md` with frontmatter fields (`name`, `description`, `allowed-tools`, `disable-model-invocation`, etc.) and a Markdown instruction body. The plugin is packaged via `.claude-plugin/plugin.json` and installs to Claude Code's plugin cache — that path is distinct from `~/.claude/skills/`, which is only where the `skill-create` skill writes user-authored output skills.

The recommended build order is `improve-prompt` first (zero filesystem dependencies, validates plugin packaging), then `skill-create` (requires pre-downloaded docs and exercises global write paths), then `workspace-create` (heaviest filesystem surface area, benefits from patterns established in prior phases). Every skill needs a carefully-written description in third-person voice with explicit trigger phrases and a "Do NOT use for" clause.

The highest-impact risks are: a permission regression in Claude Code v2.1.79+ that blocks writes to `.claude/skills/` directories (requires `settings.local.json` workaround — GitHub Issue #36497); the `AskUserQuestion` 4-option hard limit that will abort interview flows if not accounted for in question bank design (Issue #12420); and the `workspace-create` requirement to produce a fully populated CLAUDE.md from interview answers — the skill must explicitly bind each template section to a specific interview answer or it will produce stubs.

## Key Findings

### Recommended Stack

Skills require no package manager, build step, or compilation. Each skill is a directory with a `SKILL.md` entrypoint and optional supporting files. The plugin format adds a `.claude-plugin/plugin.json` manifest.

**Core technologies:**

- `SKILL.md` (YAML frontmatter + Markdown body): Primary deliverable format. No XML tags.
- `~/.claude/skills/<name>/SKILL.md`: Target path for `skill-create` output (user-authored skills).
- `.claude-plugin/plugin.json`: Plugin manifest (`name`, `description`, `author` object).
- `skills/<name>/SKILL.md` (repo-relative): Source layout for the three plugin skills.
- `${CLAUDE_SKILL_DIR}`: Runtime variable resolving to the skill's directory. Never hardcode absolute paths.
- `AskUserQuestion`: Primary interview mechanism. Hard limit: 4 options per question call.

**Frontmatter per skill:**
- `improve-prompt`: `disable-model-invocation: true`, `argument-hint: [rough-prompt-text]`
- `skill-create`: `disable-model-invocation: true`, `allowed-tools: Read Glob Grep Write Bash`
- `workspace-create`: `disable-model-invocation: true`, `allowed-tools: Write Bash`

**Canonical names:** `improve-prompt`, `skill-create`, `workspace-create`.

### Expected Features

**Must have (table stakes):**

*`/improve-prompt`:*
- `$ARGUMENTS` intake
- Single improved prompt output in chat (no file writes)
- 4 clarity dimensions: context, specificity, structure, scope
- Preserves original intent
- Shows original and improved side by side with "what changed" annotation

*`/skill-create`:*
- Reads `${CLAUDE_SKILL_DIR}/docs/` before generating
- 5-6 question interview with proposed answers (not blank questions)
- Generates valid SKILL.md frontmatter and real instruction body
- Confirms output before writing
- Writes to exactly `~/.claude/skills/<name>/SKILL.md`

*`/workspace-create`:*
- 4-5 question interview (workspace name, repos, repo purposes, overall goal)
- Full `.workspace/` scaffold (refs, docs, logs, scratch, context, outputs, sessions) + `.claude/` + `.vscode/`
- Fully populated CLAUDE.md from interview answers — no stubs
- Subdirectory README stubs with one-line purpose
- Confirms full scaffold before writing

**Defer to v2+:**
- Multiple prompt rewrite variants, prompt scoring, skill creator automated test runner, MCP server config generation, skill versioning

### Architecture Approach

Three independent skills with no shared runtime logic. No build tooling, no shared workflow layer.

**Components:**
1. `skills/improve-prompt/SKILL.md` — self-contained text transform, zero file I/O
2. `skills/skill-create/SKILL.md` + `skills/skill-create/references/` (skill-anatomy.md, writing-guide.md, naming-conventions.md)
3. `skills/workspace-create/SKILL.md` + `skills/workspace-create/templates/` (CLAUDE.md.template, dir-manifest.md)
4. `docs/` (repo root) — pre-downloaded Claude Code docs; read-only at runtime; organized with `docs/index.md`
5. `.claude-plugin/plugin.json` — plugin manifest

**Key patterns:**
- SKILL.md body stays under 500 lines — externalize reference content to `references/`
- `docs/` is read-only — `skill-create` never writes there
- `$ARGUMENTS` and user input are bounded data, not trusted instructions

### Critical Pitfalls

1. **Permission regression v2.1.79+ blocks `.claude/skills/` writes** (Issue #36497, open) — Prevention: add `Write(.claude/**)` and `Write(~/.claude/**)` to `settings.local.json` allow rules. Include pre-flight instructions in `skill-create` body. Affects: Phase 2.

2. **AskUserQuestion 4-option hard limit aborts interview flows** (Issue #12420) — Prevention: design all interview question banks with ≤4 options; use open-ended text input for repo lists. Affects: Phases 2 and 3.

3. **Workspace CLAUDE.md generates stubs instead of populated content** — Prevention: explicitly map each template placeholder to a specific interview question answer; add post-write grep validation. Affects: Phase 3.

4. **Skill saved to project scope instead of global scope** (Issue #16165) — Prevention: hardcode `~/.claude/skills/<name>/SKILL.md`; resolve `$USERPROFILE` with Bash before writing. Affects: Phase 2.

5. **Skill nesting one level too deep — silent failure** — Prevention: hardcode exact path pattern; add post-write Bash verification. Affects: Phase 2.

6. **Windows path separators cause silent write failures** (Issue #30553) — Prevention: resolve home dir with `$USERPROFILE`; construct absolute paths explicitly. Active dev environment is Windows 11 Pro. Affects: Phases 2 and 3.

## Implications for Roadmap

### Phase 0: Repo Scaffolding and Plugin Packaging
Validates packaging before any feature work. Five minutes of scaffolding prevents ambiguous failures.
**Delivers:** `.claude-plugin/plugin.json`; `skills/` directories; `docs/index.md` scaffold; install/symlink instructions; PROJECT.md correction (no `<skill>` XML tags).

### Phase 1: Prompt Improvement Skill (`/improve-prompt`)
Zero dependencies — validates end-to-end plugin packaging with no risk.
**Delivers:** `skills/improve-prompt/SKILL.md` — `$ARGUMENTS` intake, 4-dimension rewriting, "what changed" annotation.
**Research flag:** Standard patterns; no additional research needed.

### Phase 2: Skill Creator Skill (`/skill-create`)
Exercises global write paths and permission handling. Meta-bootstrap property is a useful quality check.
**Delivers:** `skills/skill-create/SKILL.md` + `skills/skill-create/references/`.
**Prerequisite (not a phase output):** `docs/` folder must be populated by user before the skill is useful. Document required files.
**Research flag:** Standard patterns; no additional research needed.

### Phase 3: Workspace Creator Skill (`/workspace-create`)
Heaviest filesystem surface. Populated CLAUDE.md is the defining quality gate.
**Delivers:** `skills/workspace-create/SKILL.md` + `templates/`.
**Research flag:** CLAUDE.md template sections may benefit from reviewing community examples before authoring.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Official Anthropic docs + verified against installed plugin sources |
| Features | HIGH | Official docs, community implementations, prior-art analysis |
| Architecture | HIGH | Empirically verified from installed plugin sources |
| Pitfalls | HIGH (one LOW) | Critical pitfalls backed by specific GitHub issue numbers; AskUserQuestion header char limits LOW |

**Overall: HIGH**

### Gaps to Address

- `improve-prompt` auto-invocation: recommend `disable-model-invocation: true` for v1
- `docs/` population process: which exact files, from where — must be in Phase 0 README
- Plugin global availability: validate cross-project loading in Phase 0
- `plugin.json` version field: unconfirmed; low risk for v1

## Sources

### Primary (HIGH confidence)
- Official Claude Code docs: slash-commands, tools-reference, sub-agents, memory pages
- `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/` — verified plugin.json schema, skills/ layout, official skill-creator (500-line guideline, progressive disclosure, references/ pattern)
- `C:/Users/dev/.claude/plugins/installed_plugins.json` — confirmed plugin cache location

### Secondary (MEDIUM confidence)
- GitHub Issues: #36497 (permission regression), #16165 (scope regression), #12420 (4-option limit), #30553 (Windows paths)
- Community analysis: skill activation rates, structural description issues in 14/23 community skills
- severity1/claude-code-prompt-improver — reference implementation

### Tertiary (LOW confidence)
- AskUserQuestion header character limits — not confirmed in official docs; design within 4-option limit regardless

---
*Research completed: 2026-04-26*
*Ready for roadmap: yes*
