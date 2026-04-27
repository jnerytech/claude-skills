# Stack Research

**Domain:** Claude Code skill authoring (slash-command-invocable SKILL.md files)
**Researched:** 2026-04-26
**Confidence:** HIGH — all findings sourced directly from https://code.claude.com/docs/en/slash-commands (the canonical Skills reference as of April 2026)

---

## Corrections to PROJECT.md

PROJECT.md line 39 (Constraints) states:

> Format: All three deliverables are Claude Code skill files (Markdown with `<skill>` structure)

**This is incorrect.** There is no `<skill>` XML structure in Claude Code. The actual format is:

- YAML frontmatter between `---` markers (configures name, description, tools, invocation mode)
- Markdown body (the instructions Claude follows when the skill runs)

The `~/.claude/skills/` storage path in PROJECT.md is correct. Only the `<skill>` structure claim is wrong. The correct format is documented in the File Format Reference section below.

---

## Terminology Clarification (Read First)

PROJECT.md uses "slash commands" and "skills" interchangeably. These are actually **unified** in current Claude Code:

- The feature is called **Skills**. Stored as `SKILL.md` files in a `skills/` directory.
- Every skill gets a `/skill-name` slash command automatically.
- **Custom commands** (`.claude/commands/name.md`) still work but are the legacy path — skills are the current standard and supersede them.
- The PROJECT.md storage path (`~/.claude/skills/`) is accurate.

**Verdict:** Build Skills (SKILL.md format), not legacy commands. They are equivalent at runtime but skills add supporting files, frontmatter-controlled invocation, and subagent integration.

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| SKILL.md (Markdown + YAML frontmatter) | Claude Code Skills spec (agentskills.io open standard) | Primary deliverable format — defines each skill | The only first-class skill format. Legacy `.claude/commands/*.md` still works but cannot bundle supporting files or use `context: fork`. All three project skills need supporting files or structured invocation control. |
| `~/.claude/skills/<name>/SKILL.md` | — | Personal skill storage path | Makes skills available globally across all Claude Code sessions without per-project config. Matches PROJECT.md requirement. |
| `.claude/skills/<name>/SKILL.md` | — | Project skill storage path | For development / testing the skill files before promoting to personal scope. Allows live-reload without restarting Claude Code. |
| YAML frontmatter | — | Skill configuration | Controls invocation mode, tool permissions, model selection, argument hints, and subagent context. Required for production-ready skills. |

### Frontmatter Fields (the "API surface" for skill authoring)

These are the fields used to configure each skill's behavior. All are optional except `description` (recommended).

| Field | Purpose | Use in This Project |
|-------|---------|---------------------|
| `name` | Slash-command name (`/name`). Defaults to directory name. Lowercase letters, numbers, hyphens, max 64 chars. | Set explicitly for all three skills: `improve-prompt`, `create-skill`, `create-workspace` |
| `description` | What the skill does and when Claude auto-invokes it. Truncated at 1,536 chars in skill listing. Front-load key use case. | Critical for all three skills. Controls whether Claude auto-triggers or only responds to `/name` invocation. |
| `when_to_use` | Supplemental trigger phrases. Appended to `description`. Counts toward 1,536-char cap. | Optional; use if description alone is not enough. |
| `disable-model-invocation` | `true` = only user can invoke via `/name`; Claude cannot auto-trigger. | Set `true` on `create-workspace` and `create-skill` — these have side effects (writing files, interviewing user) that must be user-initiated. See open question on `improve-prompt` below. |
| `allowed-tools` | Space-separated tool names granted without per-call permission prompt while skill is active. | `create-skill`: needs `Read Write Bash`. `create-workspace`: needs `Write Bash`. `improve-prompt`: no file I/O, no special tools needed. |
| `argument-hint` | Shown in autocomplete. Example: `[rough-prompt]` | Use on `improve-prompt` to tell users to pass their rough text as argument. Do not use for skills that take no arguments — omit the field instead. |
| `arguments` | Named positional argument declarations for `$name` substitution. | `improve-prompt` can use `$ARGUMENTS` to receive the rough prompt text inline. |
| `context` | `fork` = run skill in isolated subagent context (no conversation history). | Consider `context: fork` for `create-skill` if the doc-reading + interview loop is long, to preserve main context. Not required for MVP. |
| `agent` | Which subagent type to use when `context: fork` is set. Options: `Explore`, `Plan`, `general-purpose`, or custom. | If using `context: fork`, use `general-purpose` (has all tools including Write). `Explore` is read-only — cannot write files. |
| `effort` | Effort level override: `low`, `medium`, `high`, `xhigh`, `max`. | `improve-prompt`: `high` (needs careful rewriting). Others: default (inherit). |
| `model` | Model alias or full ID. | Leave as default (inherit) for all three skills unless cost control is needed. |
| `user-invocable` | `false` = hidden from `/` menu (Claude-only). | Leave default (`true`) for all three — these are user-facing commands. |

### Supporting Files (Bundled with Skills)

Skills are directories, not single files. Each can bundle additional files:

```
~/.claude/skills/
├── improve-prompt/
│   └── SKILL.md                    # Main instructions only
├── create-skill/
│   ├── SKILL.md                    # Overview + references to supporting files
│   └── docs/                       # Pre-downloaded Claude Code docs
│       ├── skills.md
│       ├── memory.md
│       └── ...                     # User downloads these before using skill
├── create-workspace/
│   ├── SKILL.md                    # Interview script + scaffold instructions
│   └── templates/
│       └── CLAUDE.md.template      # Template with $PLACEHOLDERS
└── ...
```

Key mechanism: reference supporting files from SKILL.md using relative markdown links. Claude reads them via the `Read` tool when the skill runs. The `${CLAUDE_SKILL_DIR}` variable resolves to the skill's directory at runtime — use it in shell injection commands to reference bundled scripts regardless of working directory.

### Available Tools (Skills Can Use All of These)

Tools available to skills are the full Claude Code tool set. The `allowed-tools` frontmatter pre-approves specific tools without per-call prompts. All tools remain available regardless; `allowed-tools` only affects whether the user sees an approval dialog.

| Tool | Permission Required | Relevant to Project |
|------|---------------------|---------------------|
| `Read` | No | Yes — all three skills read files |
| `Write` | Yes | Yes — `create-skill` writes to `~/.claude/skills/`, `create-workspace` creates directory structure |
| `Edit` | Yes | Optional — alternative to Write for modifying existing files |
| `Bash` | Yes | Yes — `create-workspace` needs `mkdir -p` for directory scaffolding |
| `Glob` | No | Yes — useful in `create-skill` to discover docs files |
| `Grep` | No | Yes — useful in `create-skill` to search doc content |
| `AskUserQuestion` | No | Yes — the primary mechanism for the interview loops in `create-skill` and `create-workspace` |
| `Agent` | No | Optional — can spawn subagent for isolated doc-reading in `create-skill` |
| `Skill` | Yes | Optional — can invoke other skills from within a skill |
| `WebFetch` | Yes | Explicitly excluded by PROJECT.md. Do NOT use in `create-skill`. |
| `WebSearch` | Yes | Explicitly excluded. Use pre-downloaded local docs only. |

**Critical note on `AskUserQuestion`:** This tool presents multiple-choice questions to the user. It is the correct mechanism for the interview loops in `create-skill` (asking about skill purpose, trigger phrases, tool needs) and `create-workspace` (asking about workspace name, repos, purpose). It does NOT require `allowed-tools` pre-approval. Skills can use it inline in the main conversation.

### Dynamic Context Injection (Shell Execution in Skills)

Skills support `` !`<command>` `` syntax to run shell commands before the skill content is sent to Claude. The output is injected inline. This is useful for:

- Reading directory listings: `` !`ls ${CLAUDE_SKILL_DIR}/docs/` `` to dynamically show which docs are available
- Checking environment state before interview questions

This runs at skill load time, not during Claude's tool calls. For the `create-skill` skill, inject a doc listing so Claude knows which pre-downloaded files are available without hardcoding them.

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Claude Code CLI | Running and testing skills locally | Install via `curl -fsSL https://claude.ai/install.sh \| bash`. Native Windows: `irm https://claude.ai/install.ps1 \| iex` |
| `/agents` command | Manage subagents if using `context: fork` | Built-in Claude Code command |
| `claude agents` CLI flag | List configured agents from CLI | Non-interactive |
| Live reload | Skills update without session restart | Edit files in `~/.claude/skills/` — changes take effect immediately in current session |
| `/memory` command | Inspect loaded CLAUDE.md files and toggle auto-memory | Useful during skill development to verify context loading |

---

## Installation

Skills require no package installation — they are Markdown files stored on disk. The only dependency is Claude Code itself.

```bash
# Install Claude Code (macOS/Linux)
curl -fsSL https://claude.ai/install.sh | bash

# Install Claude Code (Windows PowerShell)
irm https://claude.ai/install.ps1 | iex

# Create personal skill directories
mkdir -p ~/.claude/skills/improve-prompt
mkdir -p ~/.claude/skills/create-skill/docs
mkdir -p ~/.claude/skills/create-workspace/templates

# Test a skill (after writing SKILL.md)
claude
# Then: /improve-prompt my rough prompt text here
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `~/.claude/skills/<name>/SKILL.md` | `.claude/commands/<name>.md` (legacy) | Only when the skill needs zero supporting files AND the team is on an older Claude Code version. Avoid for new skills — Skills supersede commands. |
| `~/.claude/skills/` (personal/global) | `.claude/skills/` (project-local) | Use project-local during development for live-edit testing. Promote to personal when ready for use across all sessions. |
| `context: fork` (subagent isolation) | Inline execution (default) | Use `context: fork` only if the `create-skill` interview + doc-reading floods the main context. For MVP, inline is simpler. |
| `AskUserQuestion` for interviews | Freeform chat turns | `AskUserQuestion` presents structured choices and is better for constrained input (e.g., "Which tools does this skill need?"). Use freeform for open-ended questions where any answer is valid. Mix both within the same skill. |
| Pre-downloaded docs in `skills/create-skill/docs/` | `WebFetch` at skill runtime | WebFetch is explicitly out of scope (PROJECT.md). Pre-downloaded is also faster, offline-capable, and version-stable. |
| Relative markdown links in SKILL.md to reference supporting files | Embedding all content in SKILL.md | Supporting files keep SKILL.md under 500 lines (recommended limit). Large skills lose adherence and fill context. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `WebFetch` / `WebSearch` in `create-skill` | Explicitly prohibited by PROJECT.md. Creates network dependency and breaks offline use. | Pre-downloaded docs in `${CLAUDE_SKILL_DIR}/docs/` read with `Read` + `Glob` |
| Embedding all doc content directly in SKILL.md | Skills over 500 lines lose adherence, consume expensive context tokens every invocation even when content is not needed | Reference supporting files from SKILL.md; Claude reads them on demand |
| `user-invocable: false` on any of the three skills | These are user-facing actions, not background knowledge. Hiding them from the `/` menu defeats their purpose | Default (`true`) — keep in slash-command menu |
| `context: fork` with `agent: Explore` for write-capable skills | `Explore` is read-only (denied Write and Edit tools). `create-skill` and `create-workspace` both need to write files | Use `agent: general-purpose` if forking, or run inline (no `context: fork`) |
| `.claude/commands/` for new skill development | Legacy path. Does not support directory structure for bundled files. Skills supersede commands. | `~/.claude/skills/<name>/SKILL.md` |
| `CLAUDE.md` as the primary skill delivery mechanism | CLAUDE.md loads into every session always, consuming context budget. Skill procedures should load only when invoked. | Move multi-step procedures from CLAUDE.md to SKILL.md files |
| `argument-hint` field on skills with no arguments | The field text appears in the `/` autocomplete menu — gibberish hints are worse than no hint. | Omit `argument-hint` entirely when the skill takes no arguments |

---

## Stack Patterns by Variant

**For `improve-prompt` (read input, return improved output, no file writes):**
- Single-file skill: `~/.claude/skills/improve-prompt/SKILL.md` with no supporting files
- Set `argument-hint: [rough-prompt-text]` so users know to pass text after `/improve-prompt`
- **Open question:** Should `disable-model-invocation` be `true`? Auto-triggering when a user says "improve this prompt" could be desirable, but it risks the skill activating when users are discussing prompts rather than asking to have one rewritten. Recommend setting `disable-model-invocation: true` for v1 (explicit invocation), then relaxing to auto-trigger if user feedback shows the false-positive rate is acceptable.
- No `allowed-tools` needed — no permission-gated tools required
- Set `effort: high` to engage careful rewriting

**For `create-skill` (read local docs, interview user, write SKILL.md to `~/.claude/skills/`):**
- Directory skill with `docs/` subdirectory containing pre-downloaded Claude Code docs
- Set `disable-model-invocation: true` — writing new skill files should be user-initiated, not auto-triggered
- Set `allowed-tools: Read Glob Grep Write Bash` to pre-approve all needed tools
- Use `` !`ls ${CLAUDE_SKILL_DIR}/docs/` `` at top of SKILL.md to dynamically surface available doc files
- Use `AskUserQuestion` for structured interview (skill name, description, invocation mode, tools needed)
- Use freeform follow-up turns for open-ended questions (what should the skill actually do?)
- Write output to `~/.claude/skills/<new-skill-name>/SKILL.md` using `Write` tool

**For `create-workspace` (guided interview, scaffold directories, write CLAUDE.md):**
- Directory skill with `templates/CLAUDE.md.template` bundled
- Set `disable-model-invocation: true` — workspace creation is a major operation that must be user-initiated
- Set `allowed-tools: Write Bash` to pre-approve directory creation and file writing
- Use `AskUserQuestion` for structured interview (workspace name, repos to include, purpose)
- Use `Bash` with `mkdir -p` for scaffolding the directory structure
- Use `Write` to produce populated CLAUDE.md from interview answers — no stubs

---

## File Format Reference

Minimal valid skill:

```yaml
---
name: my-skill
description: Brief description of what this skill does and when to invoke it.
---

Skill instructions in markdown here.
```

Production skill with all relevant fields (example: `create-workspace`):

```yaml
---
name: create-workspace
description: Guided workspace setup. Interviews user about workspace name, repos to include, and purpose, then scaffolds opinionated structure with a populated CLAUDE.md. Use when starting a new multi-repo workspace.
disable-model-invocation: true
allowed-tools: Write Bash
---

Skill instructions here...

## Supporting files

- See [templates/CLAUDE.md.template](templates/CLAUDE.md.template) for the CLAUDE.md template structure.
```

Production skill with argument passing (example: `improve-prompt`):

```yaml
---
name: improve-prompt
description: Rewrites a rough prompt for clarity, specificity, context richness, and structure. Use when you want to improve a prompt before sending it.
disable-model-invocation: true
argument-hint: [rough-prompt-text]
effort: high
---

Rewrite the following prompt to be clearer, more specific, context-rich, and well-structured:

$ARGUMENTS
```

---

## Directory Layout for This Project

```
D:/repos/claude-skills/                 <- This repo (development)
├── .planning/
│   └── research/
│       └── STACK.md                   <- This file
├── skills/                            <- Source files (to be committed)
│   ├── improve-prompt/
│   │   └── SKILL.md
│   ├── create-skill/
│   │   ├── SKILL.md
│   │   └── docs/                      <- Pre-downloaded Claude Code docs (user-provided)
│   │       └── .gitkeep
│   └── create-workspace/
│       ├── SKILL.md
│       └── templates/
│           └── CLAUDE.md.template

~/.claude/skills/                       <- Deployment target (personal/global)
├── improve-prompt/
│   └── SKILL.md
├── create-skill/
│   ├── SKILL.md
│   └── docs/
│       └── *.md                       <- User downloads docs here before using skill
└── create-workspace/
    ├── SKILL.md
    └── templates/
        └── CLAUDE.md.template
```

Skills are deployed by copying (or symlinking) from the repo's `skills/` to `~/.claude/skills/`. No build step, no package manager, no compilation.

---

## Version Compatibility

| Feature | Minimum Claude Code Version | Notes |
|---------|----------------------------|-------|
| Skills / SKILL.md format | Current (as of April 2026) | Custom commands in `.claude/commands/` remain supported for backward compatibility |
| `${CLAUDE_SKILL_DIR}` variable | Current | Use to reference bundled files in shell injection |
| `AskUserQuestion` tool | Current | Available to all skills without `allowed-tools` pre-approval |
| `context: fork` / subagent execution | Current | `agent:` field determines tool set of forked context |
| Live skill reload without restart | Current | Edit files in `~/.claude/skills/` to take effect immediately |
| Auto memory (`MEMORY.md`) | v2.1.59+ | Not used by these skills directly, but context for users |

---

## Open Questions

These are unresolved decisions that should be settled during skill authoring (Phase 1):

1. **`improve-prompt` auto-invocation:** Should `disable-model-invocation` be `true` or `false`? Auto-triggering is convenient but risks false positives when users discuss prompts conversationally. Default recommendation: `true` for v1, revisit after user testing.

2. **`create-skill` doc discovery:** The `docs/` subdirectory relies on the user pre-downloading Claude Code documentation. The skill needs a clear README explaining which files to download and from where. This is a UX gap — document it during authoring.

3. **Deploy mechanism:** How will skills be installed from the repo to `~/.claude/skills/`? Options: manual copy, symlink, install script. A simple `install.sh` that symlinks each skill directory is the lowest-friction option. Decide during Phase 1.

---

## Sources

- https://code.claude.com/docs/en/slash-commands — Primary source for all skill format, frontmatter, invocation, supporting files, shell injection, and subagent integration details. **HIGH confidence** — official Anthropic documentation.
- https://code.claude.com/docs/en/tools-reference — Complete tool list with permission requirements and descriptions. **HIGH confidence** — official documentation.
- https://code.claude.com/docs/en/sub-agents — Subagent types (Explore, Plan, general-purpose), tool restrictions per agent, frontmatter fields. **HIGH confidence** — official documentation.
- https://code.claude.com/docs/en/memory — CLAUDE.md scope, directory layout, path-specific rules, skills vs CLAUDE.md tradeoffs. **HIGH confidence** — official documentation.
- https://code.claude.com/docs/en/overview — Claude Code feature overview and version context. **HIGH confidence** — official documentation.

---
*Stack research for: Claude Code skill authoring (SKILL.md format)*
*Researched: 2026-04-26*
