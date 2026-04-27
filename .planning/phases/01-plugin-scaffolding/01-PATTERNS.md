# Phase 1: Plugin Scaffolding - Pattern Map

**Mapped:** 2026-04-26
**Files analyzed:** 9 new files / 0 modified files
**Analogs found:** 5 / 9 (4 have no in-repo analog — fresh repo)

---

## File Classification

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `.claude-plugin/plugin.json` | config | static | `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/.claude-plugin/plugin.json` (external) | exact |
| `skills/improve-prompt/SKILL.md` | command-skill | request-response | `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/skills/example-command/SKILL.md` (external) | exact |
| `skills/skill-create/SKILL.md` | command-skill | request-response + file-I/O | `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/skills/example-command/SKILL.md` (external) | role-match |
| `skills/skill-create/references/` | directory | — | `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/` (external) | structural |
| `skills/workspace-create/SKILL.md` | command-skill | request-response + file-I/O | `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/skills/example-command/SKILL.md` (external) | role-match |
| `skills/workspace-create/templates/` | directory | — | `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/assets/` (external) | structural |
| `docs/index.md` | documentation | static | None — no installed plugin has a docs-index pattern | no analog |
| `README.md` | documentation | static | `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/frontend-design/README.md` (external) | partial |
| `settings.local.json.example` | config | static | None — no template found in any installed plugin | no analog |

**Note on analogs:** This is a fresh repo. All analogs are external references from the Claude Code plugin cache at `C:/Users/dev/.claude/plugins/`. They are not in-repo files. Absolute paths are provided so the planner can read them directly.

---

## Pattern Assignments

### `.claude-plugin/plugin.json` (config, static)

**Analog:** `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/.claude-plugin/plugin.json` (external)
**Match quality:** Exact — same file, same role, same schema

**Core pattern** (entire file — 8 lines):
```json
{
  "name": "example-plugin",
  "description": "A comprehensive example plugin demonstrating all Claude Code extension options including commands, agents, skills, hooks, and MCP servers",
  "author": {
    "name": "Anthropic",
    "email": "support@anthropic.com"
  }
}
```

**Adaptation for this project:**
```json
{
  "name": "claude-skills",
  "description": "<one-line plugin description>",
  "author": {
    "name": "<author name>",
    "email": "<author email>"
  }
}
```

**Second reference** (community plugin with URL-style author):
From `C:/Users/dev/.claude/plugins/cache/caveman/caveman/63e797cd753b/.claude-plugin/plugin.json` (external), lines 1-6:
```json
{
  "name": "caveman",
  "description": "Ultra-compressed communication mode...",
  "author": {
    "name": "Julius Brussee",
    "url": "https://github.com/JuliusBrussee"
  }
```
The `author` object supports either `email` or `url` — use whichever is appropriate.

**Constraints:**
- Required fields: `name`, `description`, `author`
- `name` must be the plugin identifier used in `/plugin install`
- No `version` field confirmed required; low risk to omit for v1

---

### `skills/improve-prompt/SKILL.md` (command-skill, request-response)

**Analog:** `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/skills/example-command/SKILL.md` (external)
**Match quality:** Exact — user-invoked slash command with `$ARGUMENTS` intake, no file writes

**Frontmatter pattern** (lines 1-6 of analog):
```yaml
---
name: example-command
description: An example user-invoked skill that demonstrates frontmatter options and the skills/<name>/SKILL.md layout
argument-hint: <required-arg> [optional-arg]
allowed-tools: [Read, Glob, Grep, Bash]
---
```

**Frontmatter for `improve-prompt`** (copy and adapt):
```yaml
---
name: improve-prompt
description: <third-person description with trigger phrases — e.g., "Use when the user asks to improve, rewrite, or clarify a prompt, or invokes /improve-prompt.">
argument-hint: <rough-prompt-text>
disable-model-invocation: true
---
```

**Key constraints from research:**
- `disable-model-invocation: true` — required for all three skills (v1 decision, locked from research)
- `argument-hint` — shown in `/help`; use angle-bracket notation for required args, square brackets for optional
- No `allowed-tools` needed — this skill makes no file I/O calls
- Description must be written in third-person voice with explicit trigger phrases and a "Do NOT use for" clause

**`$ARGUMENTS` body pattern** (analog body, line 12 of example-command SKILL.md):
```markdown
The user invoked this with: $ARGUMENTS
```
Copy this pattern verbatim as the intake line; the skill body then acts on `$ARGUMENTS`.

**Body structure to follow:**
```markdown
---
[frontmatter]
---

# Improve Prompt

The user invoked this with: $ARGUMENTS

## Instructions

[skill body — what Claude must do]
```

---

### `skills/skill-create/SKILL.md` (command-skill, request-response + file-I/O)

**Analog:** `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/skills/example-command/SKILL.md` (external) — for frontmatter structure

**Secondary reference:** `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/SKILL.md` (external) — for interview flow patterns (lines 46-70 of that file show the "Capture Intent" interview stage)

**Frontmatter for `skill-create`** (adapt from analog):
```yaml
---
name: skill-create
description: <third-person description with trigger phrases>
argument-hint: [skill-description]
allowed-tools: [Read, Glob, Grep, Write, Bash]
disable-model-invocation: true
---
```

**Key constraints from research:**
- `allowed-tools: [Read, Glob, Grep, Write, Bash]` — required for docs read + global skill write
- `disable-model-invocation: true` — locked from research
- Body must reference `${CLAUDE_SKILL_DIR}/docs/` as the docs read path (runtime variable, never hardcode)
- `AskUserQuestion` hard limit: 4 options per question call — design interview bank around this
- Write target: `$USERPROFILE/.claude/skills/<name>/SKILL.md` (Windows — use `$USERPROFILE`, not `~`)

**Interview stage reference** (from skill-creator official plugin, lines 46-56):
```markdown
### Capture Intent

Start by understanding the user's intent. The current conversation might already contain a workflow the user wants to capture...

1. What should this skill enable Claude to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases to verify the skill works?
```

Note: This is a reference pattern for interview structure, not for literal copying. The 4-option AskUserQuestion limit overrides any open-ended list patterns from this source.

---

### `skills/skill-create/references/` (directory, structural)

**Analog:** `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/` (external) — has `references/` subdirectory with supporting docs

**Pattern:** The `references/` directory holds Markdown files that the skill reads on demand. Contents are NOT loaded into context automatically — the SKILL.md body must explicitly instruct Claude to read specific reference files when needed.

**Structural reference** (from skill-creator official plugin directory listing):
```
skill-creator/
├── SKILL.md
├── references/
│   └── schemas.md        ← loaded on demand, not at skill activation
├── agents/
├── assets/
└── scripts/
```

**For Phase 1 stub:** Create `skills/skill-create/references/` as an empty directory placeholder. Phase 3 populates it with `skill-anatomy.md`, `writing-guide.md`, `naming-conventions.md`.

**Git note:** Git does not track empty directories. Add a `.gitkeep` file to ensure the directory is committed:
```
skills/skill-create/references/.gitkeep
```

---

### `skills/workspace-create/SKILL.md` (command-skill, request-response + file-I/O)

**Analog:** `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/skills/example-command/SKILL.md` (external)
**Match quality:** Role-match — same user-invoked slash command pattern; heavier file-I/O than improve-prompt

**Frontmatter for `workspace-create`** (adapt from analog):
```yaml
---
name: workspace-create
description: <third-person description with trigger phrases>
allowed-tools: [Write, Bash]
disable-model-invocation: true
---
```

**Key constraints from research:**
- `allowed-tools: [Write, Bash]` — only needs Write (scaffold dirs) and Bash (mkdir, cp)
- `disable-model-invocation: true` — locked from research
- Phase 1 stub only — body content written in Phase 4
- Phase 4 needs `skills/workspace-create/templates/` to exist before work begins

---

### `skills/workspace-create/templates/` (directory, structural)

**Analog:** `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/assets/` (external) — closest structural match for template/asset directories
**Match quality:** Structural — same directory-as-supporting-files pattern

**Pattern:** Template files live here (e.g., `CLAUDE.md.template`, `dir-manifest.md`). The SKILL.md body references them by path via `${CLAUDE_SKILL_DIR}/templates/`.

**For Phase 1 stub:** Create `skills/workspace-create/templates/` as an empty directory placeholder with `.gitkeep`.

---

### `docs/index.md` (documentation, static)

**No analog found.** No installed plugin in the cache has a docs-index pattern. This file is unique to this project's `skill-create` runtime requirement.

**Design from CONTEXT and REQUIREMENTS:**
- SETUP-03: "lists exactly which Claude Code documentation files to download and where to place them"
- Runtime use: `skill-create` reads `${CLAUDE_SKILL_DIR}/docs/` first; `docs/index.md` is the entry point
- The `docs/` folder is read-only at runtime — `skill-create` reads it, never writes to it

**Recommended format for planner** (no analog — use readability-first design):
```markdown
# Claude Code Documentation Index

List each documentation file the user must download, its source URL, and target filename under `docs/`.

| File | Source | Purpose |
|------|--------|---------|
| `docs/slash-commands.md` | <source URL> | How slash commands and skills work |
| `docs/tools-reference.md` | <source URL> | Available tools and their parameters |
```

**Planner should design this file's schema** — CONTEXT notes this is Claude's discretion.

---

### `README.md` (documentation, static)

**Analog:** `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/frontend-design/README.md` (external)
**Match quality:** Partial — same role (plugin README), different content depth needed

**Pattern from analog** (entire 31-line file):
```markdown
# Frontend Design Plugin

Generates distinctive, production-grade frontend interfaces...

## What It Does

Claude automatically uses this skill for frontend work. Creates production-ready code with:
- Bold aesthetic choices
...

## Usage

```
"Create a dashboard for a music streaming app"
```

## Authors

Prithvi Rajasekaran (prithvi@anthropic.com)
```

**Adaptation for this project:**

Per D-01 and D-02 from CONTEXT, README must include a "Getting Started" section with:
1. Prerequisites
2. Clone step
3. `/plugin install <local-repo-path>` command

**Recommended Getting Started structure:**
```markdown
## Getting Started

**Prerequisites:** Claude Code installed and running.

1. Clone this repo:
   ```
   git clone <repo-url> <local-path>
   ```

2. Install the plugin:
   ```
   /plugin install <local-path>
   ```

The plugin's three skills are now available as slash commands.
```

---

### `settings.local.json.example` (config, static)

**No analog found.** No `settings.local.json.example` file exists in any installed plugin or the Claude config directory.

**Design from CONTEXT D-03 and D-04 (locked decisions):**

D-03: Template committed as `settings.local.json.example`. Users copy to `settings.local.json`.
D-04: Include all four allow rules needed by downstream skills.

**Exact content to create** (derived directly from CONTEXT decisions):
```json
{
  "permissions": {
    "allow": [
      "Write(.claude/**)",
      "Write(~/.claude/**)",
      "Bash(mkdir:**)",
      "Bash(cp:**)"
    ]
  }
}
```

**Note on `~` vs `$USERPROFILE`:** The allow rules in `settings.local.json` use `~/.claude/**` — this is correct. The `~` here is interpreted by Claude Code's permission engine, not by the shell. The `$USERPROFILE` convention (D-06) applies only to paths written inside SKILL.md bodies, where the shell resolves the path at skill execution time. Do not conflate these two contexts.

**Users must:**
1. Copy `settings.local.json.example` → `settings.local.json` at the workspace root
2. `settings.local.json` must NOT be committed (add to `.gitignore`)

---

## Shared Patterns

### Plugin Manifest Schema
**Source:** `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/.claude-plugin/plugin.json` (external)
**Apply to:** `.claude-plugin/plugin.json`
```json
{
  "name": "<plugin-id>",
  "description": "<one-line description>",
  "author": {
    "name": "<name>",
    "email": "<email>"
  }
}
```

### User-Invoked Skill Frontmatter
**Source:** `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/skills/example-command/SKILL.md` lines 1-6 (external)
**Apply to:** All three SKILL.md files (`improve-prompt`, `skill-create`, `workspace-create`)

Minimal required frontmatter for a user-invoked slash command:
```yaml
---
name: <skill-name>
description: <trigger description>
disable-model-invocation: true
---
```

Optional frontmatter fields (use as appropriate per skill):
```yaml
argument-hint: <arg-description>     # shown in /help — use for improve-prompt
allowed-tools: [Tool1, Tool2]        # pre-approved tools — use for skill-create and workspace-create
```

### `$ARGUMENTS` Intake Pattern
**Source:** `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/skills/example-command/SKILL.md` line 12 (external)
**Apply to:** `improve-prompt` (takes user's rough prompt as `$ARGUMENTS`)
```markdown
The user invoked this with: $ARGUMENTS
```

### `${CLAUDE_SKILL_DIR}` Path Variable
**Source:** Research SUMMARY.md — confirmed convention from official docs
**Apply to:** `skill-create/SKILL.md` body (for docs read path)

Never hardcode absolute paths in SKILL.md bodies. Use the runtime variable:
```
${CLAUDE_SKILL_DIR}/docs/          ← reads docs at skill's own directory
${CLAUDE_SKILL_DIR}/references/    ← reads reference files on demand
${CLAUDE_SKILL_DIR}/templates/     ← reads templates for workspace-create
```

### Windows Write Path Pattern
**Source:** Research SUMMARY.md + CONTEXT D-06 (locked decision)
**Apply to:** `skill-create/SKILL.md` body (when writing to global skills path)

Inside SKILL.md bodies that invoke Bash or Write to the user's home directory:
```
$USERPROFILE/.claude/skills/<name>/SKILL.md    ← correct (Windows)
~/.claude/skills/<name>/SKILL.md               ← WRONG on Windows — do not use in skill bodies
```

### `disable-model-invocation: true`
**Source:** Research SUMMARY.md (v1 decision, HIGH confidence)
**Apply to:** All three SKILL.md files

All three skills are user-invoked slash commands. Set `disable-model-invocation: true` in every SKILL.md frontmatter to prevent unintended auto-invocation by the model.

---

## No Analog Found

Files with no close match in the codebase or installed plugins (planner uses CONTEXT/RESEARCH patterns instead):

| File | Role | Reason |
|------|------|--------|
| `docs/index.md` | documentation | No installed plugin has a docs-index pattern; format is Claude's discretion per CONTEXT |
| `settings.local.json.example` | config template | No `settings.local.json` template found anywhere in plugin cache; content derived from CONTEXT D-03/D-04 |

---

## Metadata

**Analog search scope:** `C:/Users/dev/.claude/plugins/` (all installed and cached plugins)
**External plugins examined:** `example-plugin`, `skill-creator`, `frontend-design`, `caveman`, `obsidian`
**In-repo files scanned:** 1 (`CLAUDE.md` — confirmed fresh repo)
**Pattern extraction date:** 2026-04-26

**Analog limitations:** All analogs are external (from the Claude Code plugin cache). The repo is fresh — no in-repo patterns exist yet. Phase 1 establishes the baseline that Phases 2–4 will copy from within the repo.
