# Phase 4: Workspace Creator Skill - Research

**Researched:** 2026-04-29
**Domain:** Claude Code SKILL.md body authoring — interview-driven workspace scaffolder with multi-directory file writes
**Confidence:** HIGH (structure, constraints, patterns from prior phases) / MEDIUM (CLAUDE.md template design) / LOW (some behavioral assumptions — see Assumptions Log)

---

## Summary

Phase 4 writes the instruction body of `skills/workspace-create/SKILL.md`. The stub already has correct final frontmatter (`allowed-tools: [Write, Bash]`, `disable-model-invocation: true`). The executor replaces the placeholder comment block with a working Markdown body — no frontmatter changes.

The skill is the most structurally complex of the three skills: it conducts a mixed interview (mostly chat-level freeform, not AskUserQuestion), scaffolds 10 directories with individual READMEs, and generates a fully-populated CLAUDE.md derived from interview answers. The target workspace is created in the CWD (or a named subdirectory of it) where Claude Code was invoked — not at a fixed global path like Phase 3.

Phase 4 has **two deliverables** that the planner must address:
1. `skills/workspace-create/SKILL.md` — the full instruction body
2. `skills/workspace-create/templates/CLAUDE.md.template` — the template the skill loads at runtime (currently only `.gitkeep` exists in the templates/ dir)

**Primary recommendation:** Write the skill body as a linear sequence of numbered stages (guard check, interview, confirm, scaffold, generate CLAUDE.md, confirm write). Use a concrete CLAUDE.md template file rather than building inline — separation of structure from instruction content makes both easier to maintain. CLAUDE.md sections must be populated by inline replacement of `{{VARIABLE}}` markers from interview answers; no bracket stubs in the final output.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Guided interview | SKILL.md inline (Claude) | — | Chat freeform for variable-length inputs; AskUserQuestion for fixed binary choices |
| Directory scaffolding | Bash (mkdir -p) | — | Multiple directories, must be created before Write calls; CWD-relative paths |
| File creation (READMEs, CLAUDE.md) | Write tool | Bash (for path resolution) | Each subdirectory gets a one-line README; CLAUDE.md gets full populated template |
| CLAUDE.md generation | SKILL.md body (Claude reasoning) | Template file | Claude reads template, replaces markers with interview answers, produces output under 200 lines |
| Confirmation gate | Chat-level reply | — | One "Shall I write all these files?" after showing scaffold plan — not AskUserQuestion |

---

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| SKILL.md body | Markdown | Instruction content Claude executes | Required by skills platform |
| YAML frontmatter | Already final in stub | Invocation config | Platform-required; do not modify |
| `allowed-tools: [Write, Bash]` | Already final | File creation + directory creation | Write creates files; Bash runs mkdir -p |
| `disable-model-invocation: true` | Already final | User-only slash command | Prevents ambient auto-invocation |
| `$ARGUMENTS` substitution | Built-in | Receives optional workspace name hint | Only input channel at invocation time |
| `${CLAUDE_SKILL_DIR}` substitution | Built-in | Resolves path to templates/ at runtime | Required for portable template read |
| Write tool | In allowed-tools | Creates all scaffold files (READMEs, CLAUDE.md) | Standard file write pattern |
| Bash tool | In allowed-tools | mkdir -p for all directories; path resolution | Write fails without parent dirs existing |

[VERIFIED: skills/workspace-create/SKILL.md stub, prior phases research]

**No npm packages. No external libraries. No network calls.**

### Second Deliverable: CLAUDE.md Template

The stub comment on line 17 reads: `Load ${CLAUDE_SKILL_DIR}/templates/CLAUDE.md.template and populate from interview answers`

Checking the templates directory:
```
skills/workspace-create/templates/
└── .gitkeep    (empty placeholder — template does NOT exist yet)
```

[VERIFIED: ls skills/workspace-create/templates/ returned only .gitkeep]

The template file must be created as part of Phase 4. **Two design choices for the planner:**

| Approach | Trade-off |
|----------|-----------|
| A) Template file: Create `skills/workspace-create/templates/CLAUDE.md.template` with `{{VARIABLE}}` markers; skill loads it via Read and replaces markers | Cleanest separation — template maintainable without reading SKILL.md; executor has clear second artifact to write |
| B) Inline generation: Skill body carries full CLAUDE.md structure as a prose template embedded in instructions | Simpler runtime (no Read call needed); but mixing template content with instructions bloats SKILL.md |

[ASSUMED — Approach A is recommended; either is valid. Planner decides.]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `${CLAUDE_SKILL_DIR}/templates/` path | Hardcoded path | Hardcoded breaks on different install locations — always use `${CLAUDE_SKILL_DIR}` |
| Chat-level "Write it?" gate | AskUserQuestion | Chat gate is lighter-weight after a long interview; same pattern used in Phase 3 |
| AskUserQuestion for repo list | Chat freeform | AskUserQuestion can't carry variable-length lists — repo names are freeform strings |

---

## Architecture Patterns

### System Architecture Diagram

```
User invokes /workspace-create [optional workspace-name-hint]
        |
        v
[1] Empty-args not required — but check if CWD is appropriate
    Ask: "Where should the workspace root be created?" (freeform chat)
    Validate: workspace name is kebab-safe, no spaces/special chars
        |
        v
[2] Interview — MIXED: chat-freeform + AskUserQuestion
    Q1 (chat): Workspace name   → used as root dir name
    Q2 (chat): Repos to include → comma-separated list
    Q3 (chat, iterative): Per-repo purpose → one answer per repo named
    Q4 (chat): Overall workspace goal → 1-3 sentences
    Q5 (chat): Primary language/stack? → optional, used in CLAUDE.md conventions
    [Optional AskUserQuestion only if a binary choice arises]
        |
        v
[3] Preview scaffold plan in chat — show directory tree + CLAUDE.md outline
    Ask in chat: "Shall I create all these? Reply 'yes' or describe changes."
        |
        v
[4] Validate workspace name (^[a-z][a-z0-9-]*$ no spaces, no special chars)
    Determine workspace root path (CWD/<workspace-name>/)
    mkdir -p for each directory:
      <root>/.workspace/refs/
      <root>/.workspace/docs/
      <root>/.workspace/logs/
      <root>/.workspace/scratch/
      <root>/.workspace/context/
      <root>/.workspace/outputs/
      <root>/.workspace/sessions/
      <root>/.claude/
      <root>/.vscode/
        |
        v
[5] Write one-line READMEs in each .workspace/ subdir
        |
        v
[6] Read ${CLAUDE_SKILL_DIR}/templates/CLAUDE.md.template
    Replace {{VARIABLES}} with interview answers
    Verify result is under 200 lines
    Write to <root>/CLAUDE.md
        |
        v
[7] Confirm in chat:
    "Workspace <name> created at ./<name>/.
     CLAUDE.md populated. Open it now."
```

### Recommended Project Structure (what the skill CREATES for the user)

```
<workspace-name>/          ← created in CWD where Claude was invoked
├── CLAUDE.md              ← fully populated from interview answers
├── .workspace/
│   ├── refs/
│   │   └── README.md      ← "Reference materials and external resources for this workspace."
│   ├── docs/
│   │   └── README.md      ← "Documentation files and guides for workspace projects."
│   ├── logs/
│   │   └── README.md      ← "Session logs and activity records."
│   ├── scratch/
│   │   └── README.md      ← "Temporary scratch space for experiments and drafts."
│   ├── context/
│   │   └── README.md      ← "Persistent context files shared across sessions."
│   ├── outputs/
│   │   └── README.md      ← "Generated outputs and artifacts from Claude sessions."
│   └── sessions/
│       └── README.md      ← "Per-session working directories."
├── .claude/
│   └── settings.local.json  ← permissions template (optional but useful; see edge cases)
└── .vscode/
    └── .gitkeep           ← ensures dir is tracked if repo'd; user adds their own config
```

[ASSUMED — exact README wording and .claude/.vscode minimal contents; planner decides]

### Pattern 1: Chat-Freeform Interview for Variable-Length Inputs

**What:** For inputs that are variable-length (repo list, per-repo purpose), the skill asks in chat and collects the answer. Not AskUserQuestion.
**When to use:** Any interview question where the answer is a free string or a list.

```markdown
<!-- In skill body -->
## Gather workspace details

Ask each question in sequence in chat. Wait for the user's reply before proceeding.

1. "What should I name this workspace? (Used as the directory name — lowercase letters, numbers, hyphens only)"
2. "Which repos will this workspace include? List them separated by commas or newlines."
3. For each repo named: "What is the purpose of <repo>?"
4. "In 1-3 sentences, what is the overall goal of this workspace?"
5. (Optional) "What is the primary language or stack? (Leave blank to skip)"
```

[VERIFIED: AskUserQuestion limit constraint from CLAUDE.md + STATE.md; chat-freeform is the correct pattern for variable inputs]

**Constraint:** AskUserQuestion has a hard limit of 4 options total (3 explicit + auto-"Other"). For workspace name, repo list, and per-repo purpose — all of which are freeform strings — AskUserQuestion is the wrong tool. Use chat.

### Pattern 2: Preview Before Write (from Phase 3)

**What:** After interview, show a directory tree + first ~10 lines of CLAUDE.md preview. Ask chat-level "yes/describe changes" before any mkdir/Write.
**When to use:** D-10 carry-forward from Phase 3; essential for user confidence before heavy file writes.

```markdown
## Scaffold plan

Show the user:
1. The directory tree the skill will create
2. A preview of the CLAUDE.md header and first two sections
Then ask: "Shall I create all these files? Reply 'yes' to proceed or describe changes."
```

[VERIFIED: Phase 3 SKILL.md preview + confirm pattern]

### Pattern 3: mkdir -p Then Write Sequence (carry-forward from Phase 3)

**What:** For every file created, its parent directory must exist first. With 7 subdirs + 7 READMEs + CLAUDE.md, the sequence is: mkdir-all-dirs → write-READMEs → read-template → write-CLAUDE.md.
**When to use:** All file scaffold stages.

```bash
# Resolve workspace root — use absolute path from CWD + workspace name
WORKSPACE_ROOT="$(pwd)/<validated-name>"
# Or if user specified an absolute path: WORKSPACE_ROOT="<user-provided-path>"

mkdir -p "$WORKSPACE_ROOT/.workspace/refs"
mkdir -p "$WORKSPACE_ROOT/.workspace/docs"
mkdir -p "$WORKSPACE_ROOT/.workspace/logs"
mkdir -p "$WORKSPACE_ROOT/.workspace/scratch"
mkdir -p "$WORKSPACE_ROOT/.workspace/context"
mkdir -p "$WORKSPACE_ROOT/.workspace/outputs"
mkdir -p "$WORKSPACE_ROOT/.workspace/sessions"
mkdir -p "$WORKSPACE_ROOT/.claude"
mkdir -p "$WORKSPACE_ROOT/.vscode"
```

[ASSUMED — pwd used for CWD resolution; planner should verify this is correct on Windows/git-bash]

### Pattern 4: CLAUDE.md Template Variable Replacement

**What:** The skill reads the template file, replaces `{{WORKSPACE_NAME}}`, `{{WORKSPACE_GOAL}}`, `{{REPO_MAP}}`, etc. with actual interview answers, then writes the result.
**When to use:** Stage 6 (generate CLAUDE.md).

```markdown
## Generate CLAUDE.md

Read `${CLAUDE_SKILL_DIR}/templates/CLAUDE.md.template`.

Replace each marker with the corresponding interview answer:
- `{{WORKSPACE_NAME}}` → workspace name from Q1
- `{{WORKSPACE_GOAL}}` → overall goal from Q4
- `{{REPO_MAP}}` → formatted table: | Repo | Purpose | for each repo+purpose pair
- `{{STACK}}` → primary stack from Q5, or "Not specified" if blank
- `{{CREATED_DATE}}` → today's date (YYYY-MM-DD)

Verify the result is under 200 lines before writing.
Write to `<WORKSPACE_ROOT>/CLAUDE.md`.
```

[ASSUMED — exact marker names; planner adapts when writing the template file]

### Pattern 5: Workspace Name Validation

**What:** Workspace name becomes a directory name — validate before any mkdir.
**When to use:** After Q1 answer received, before showing the scaffold plan.

```bash
# Validate workspace name: lowercase, alphanumeric, hyphens only; no spaces; no path components
NAME="<user-supplied-name>"
if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*$ ]] || [[ "$NAME" == *".."* ]] || [[ "$NAME" == *"/"* ]]; then
  echo "Invalid workspace name: use lowercase letters, numbers, and hyphens only."
  # Re-ask Q1
fi
```

[ASSUMED — exact regex; same pattern as Phase 3 name validation with small tweak to require leading letter]

### Anti-Patterns to Avoid

- **AskUserQuestion for repo names or purposes:** The 4-option limit cannot carry N variable-length strings. These must be chat-freeform.
- **Relative paths in mkdir/Write calls:** Always resolve `WORKSPACE_ROOT` as an absolute path from `$(pwd)`. Relative paths shift if CWD changes within a Bash chain.
- **Writing CLAUDE.md before all directories exist:** The CLAUDE.md Write can fail or succeed depending on tool behavior with missing parent dirs — always mkdir all dirs first.
- **Leaving `{{VARIABLE}}` markers unreplaced in CLAUDE.md:** WORK-05 requires zero stubs. Every marker must be replaced with real content, even if the user's answer was minimal.
- **Using `~` for workspace paths:** The workspace root is derived from CWD, not from `$HOME` — `~` doesn't enter this picture at all. The only `~` risk would be if `.claude/` inside the workspace is confused with `~/.claude/`; keep them distinct.
- **4 explicit options in AskUserQuestion:** If any binary question arises (e.g., "include settings.local.json?"), use ≤3 explicit options.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Workspace name validation | Manual char loop | `^[a-z][a-z0-9-]*$` regex in Bash | Handles all edge cases; same pattern validated in Phase 3 |
| Directory creation with existence check | Check-then-mkdir | `mkdir -p` unconditionally | Idempotent; handles all parent creation in one call |
| CLAUDE.md template variable replacement | String-building in skill body | Read template file + marker replacement | Keeps template maintainable; SKILL.md stays readable |
| Scaffold plan display | Custom tree builder | Inline Markdown code block with hardcoded structure | The dir structure is fixed; no need for dynamic tree generation |

**Key insight:** The skill body instructs Claude, not a program. Don't design complex conditional code — use simple ordered stages with clear decision points.

---

## CLAUDE.md Template Design

The template lives at `skills/workspace-create/templates/CLAUDE.md.template`. It must:
- Be under 200 lines when populated [VERIFIED: CLAUDE.md key constraints]
- Have zero stubs/unfilled placeholders after population [VERIFIED: WORK-05, CLAUDE.md key constraints]
- Cover the sections most useful for a multi-repo workspace

### Proposed Sections and Line Budget

| Section | Purpose | Approx Lines |
|---------|---------|-------------|
| `# {{WORKSPACE_NAME}}` + goal paragraph | Workspace identity | 4 |
| `## Repositories` | Table: repo name, purpose | 2 + N rows |
| `## Workspace Goal` | Verbatim from interview Q4 | 3-5 |
| `## Directory Map` | `.workspace/` subdir purposes | 12 |
| `## Session Conventions` | How to start/end sessions, log location | 10 |
| `## Stack / Language` | From Q5 or "Not specified" | 3 |
| `## Constraints` | Things Claude should never do in this workspace | 5 |
| Buffer | Variable content + blank lines | ~10 |
| **Total** | | ~50-55 base + N repo rows |

At 5 repos, total ≈ 60 lines. Budget is well within 200 lines even for large workspaces.

[ASSUMED — exact section headings and content; planner and/or discuss-phase should validate against user expectations]

### Template Marker List

| Marker | Populated From | Fallback if Blank |
|--------|---------------|-------------------|
| `{{WORKSPACE_NAME}}` | Q1 answer | Required — re-ask until provided |
| `{{WORKSPACE_GOAL}}` | Q4 answer | Required — re-ask until provided |
| `{{REPO_MAP}}` | Q2+Q3 answers (table rows) | "No repos specified" |
| `{{STACK}}` | Q5 answer | "Not specified" |
| `{{CREATED_DATE}}` | Current date (Bash `date +%Y-%m-%d`) | Required — Bash resolves it |
| `{{CONVENTIONS}}` | Derived from stack + goal | Default text: "Follow standard conventions for the stack" |

[ASSUMED — exact marker names and fallback behavior; planner defines final list]

---

## .workspace/ Subdirectory READMEs

Each `.workspace/` subdirectory gets exactly one-line README.md explaining its purpose.

| Directory | Proposed README.md content |
|-----------|---------------------------|
| `.workspace/refs/` | `Reference materials and external resources for this workspace.` |
| `.workspace/docs/` | `Documentation files and guides for workspace projects.` |
| `.workspace/logs/` | `Session logs and activity records.` |
| `.workspace/scratch/` | `Temporary scratch space for experiments and drafts.` |
| `.workspace/context/` | `Persistent context files shared across sessions.` |
| `.workspace/outputs/` | `Generated outputs and artifacts from Claude sessions.` |
| `.workspace/sessions/` | `Per-session working directories.` |

[ASSUMED — exact wording; planner may adjust]

---

## .claude/ and .vscode/ Minimum Content

WORK-04 requires only that these directories **exist** — no content specified.

| Directory | Minimum | Recommended |
|-----------|---------|-------------|
| `.claude/` | Empty or `.gitkeep` | `settings.local.json` with `Write(.claude/**)` allow rule (mirrors Phase 1 template) |
| `.vscode/` | Empty or `.gitkeep` | `.gitkeep` to preserve the dir in git; user adds their own settings |

[ASSUMED — recommendation for settings.local.json in .claude/; WORK-04 only requires existence]

**Key distinction:** `.claude/` inside the workspace root is for that workspace's Claude Code settings. It is different from `~/.claude/` (global). The permission regression workaround (`Write(~/.claude/**)`) applies to global writes. For workspace-local `.claude/`, no special allow rule is needed from the skill's perspective — the Write tool can write to CWD-relative paths without the global exception.

---

## Critical Open Design Questions

These questions have no CONTEXT.md to resolve them. They are `[ASSUMED]` and must be surfaced to the user or decided by the planner before execution.

### Q1: Where is the workspace root created?

**The pivotal question for Phase 4.** Options:

| Option | Behavior | Implication |
|--------|----------|-------------|
| A) CWD subdirectory | `mkdir <workspace-name>` in CWD where Claude Code runs | User must cd to the right parent before invoking; most natural |
| B) Absolute path from user | Skill asks for full path | Flexible but adds interview friction |
| C) CWD itself | Workspace files go directly in CWD | Risky — pollutes existing repos |

**Recommendation [ASSUMED]:** Option A. Stub comment says workspace name "becomes a directory name" — implies it's a new directory, not CWD itself. Interview Q1 should confirm or let user override.

### Q2: Template file vs inline generation?

Option A (template file) keeps concerns separated; recommended. Requires two tasks in PLAN.md.
Option B (inline) is simpler but bloats SKILL.md. Not recommended.

[ASSUMED — planner decides]

### Q3: What happens if `.workspace/` already exists in CWD?

No behavior specified. Options: warn + stop, warn + continue, silently overwrite. Recommend: warn + ask (same pattern as Phase 3 overwrite warning).

[ASSUMED — planner decides]

### Q4: Should `.claude/settings.local.json` be written inside the workspace?

WORK-04 says create `.claude/` directory — no content specified. Adding `settings.local.json` is a useful UX improvement but is not required by WORK-04. Recommend: write it (useful, low cost). If the planner agrees, it's one extra Write call in the scaffold stage.

[ASSUMED]

---

## Common Pitfalls

### Pitfall 1: AskUserQuestion for Variable-Length Inputs

**What goes wrong:** Skill uses AskUserQuestion for "which repos?" — user can only pick from 4 fixed options. Can't name their actual repos.
**Why it happens:** Phase 3 used AskUserQuestion for all 4 interview topics; that pattern doesn't transfer to Phase 4.
**How to avoid:** Chat-level questions for all freeform + variable-length inputs. AskUserQuestion only for fixed binary/ternary choices.
**Warning signs:** AskUserQuestion call for workspace name, repo list, or per-repo purpose in the skill body.

[VERIFIED: AskUserQuestion ≤4 option limit from CLAUDE.md + STATE.md]

### Pitfall 2: Relative Paths in mkdir/Write

**What goes wrong:** `mkdir -p .workspace/refs` works from the right directory, fails silently from another.
**Why it happens:** Bash CWD can shift; Claude may be invoked from a different directory.
**How to avoid:** Resolve workspace root as absolute path once with `$(pwd)/<workspace-name>` at the top of the scaffold stage. Use that absolute variable for all subsequent mkdir/Write calls.
**Warning signs:** Any mkdir/Write using a relative path like `.workspace/refs` without first establishing an absolute root.

[ASSUMED — pwd behavior in git-bash on Windows; verify with planner]

### Pitfall 3: CLAUDE.md Stubs Reaching Output

**What goes wrong:** Template marker `{{WORKSPACE_GOAL}}` not replaced because Q4 answer was blank or not captured.
**Why it happens:** Freeform interview may produce empty or off-topic answers.
**How to avoid:** For required markers (`{{WORKSPACE_NAME}}`, `{{WORKSPACE_GOAL}}`), re-ask if the answer is blank. For optional markers (`{{STACK}}`), apply a fallback string ("Not specified"). Never write `{{VARIABLE}}` to the final CLAUDE.md.
**Warning signs:** Skill body has no handling for blank interview answers.

[VERIFIED: WORK-05 requirement + CLAUDE.md constraint "no stubs, no unfilled placeholders"]

### Pitfall 4: Writing CLAUDE.md Before Directories Exist

**What goes wrong:** Write to `<root>/CLAUDE.md` fails if `<root>` dir was not created first.
**Why it happens:** mkdir and Write stages interspersed incorrectly.
**How to avoid:** All mkdir calls run in a single Bash block before any Write call. Order: mkdir-all → write-READMEs → write-CLAUDE.md.

[VERIFIED: Phase 3 Research Pitfall 4 — same constraint applies]

### Pitfall 5: CLAUDE.md Over 200 Lines

**What goes wrong:** Large repo list + verbose answers push CLAUDE.md over the 200-line constraint.
**Why it happens:** Template + N repo rows + verbose text can accumulate.
**How to avoid:** After variable replacement, count lines. If ≥195, trim the repo table to summary form and truncate `{{CONVENTIONS}}` section. Verify in skill body's final checks.
**Warning signs:** No line-count verification step in the skill body.

[VERIFIED: CLAUDE.md key constraints — 200-line hard limit]

### Pitfall 6: `~` vs Workspace `.claude/`

**What goes wrong:** Skill confuses `~/.claude/` (global) with `./<workspace>/.claude/` (local). Uses `$USERPROFILE` for a path that should be CWD-relative.
**Why it happens:** Phase 3 established the `$USERPROFILE` pattern for global writes; Phase 4 doesn't write anything to `~/.claude/`.
**How to avoid:** All Phase 4 paths are relative to `WORKSPACE_ROOT`. Never use `$USERPROFILE` in Phase 4's write paths.
**Warning signs:** `$USERPROFILE` appearing in mkdir or Write calls in the scaffold stage.

---

## Code Examples

### CWD-Based Workspace Root Resolution

```bash
# Source: ASSUMED — $(pwd) in git-bash on Windows returns /d/repos/... form
WORKSPACE_NAME="my-workspace"  # from interview
WORKSPACE_ROOT="$(pwd)/$WORKSPACE_NAME"
mkdir -p "$WORKSPACE_ROOT/.workspace/refs"
mkdir -p "$WORKSPACE_ROOT/.workspace/docs"
# ... etc.
```

[ASSUMED — pwd format on Windows git-bash; planner should verify]

### All mkdir -p Calls in One Bash Block

```bash
# Scaffold all directories atomically
WORKSPACE_ROOT="$(pwd)/<validated-name>"
mkdir -p \
  "$WORKSPACE_ROOT/.workspace/refs" \
  "$WORKSPACE_ROOT/.workspace/docs" \
  "$WORKSPACE_ROOT/.workspace/logs" \
  "$WORKSPACE_ROOT/.workspace/scratch" \
  "$WORKSPACE_ROOT/.workspace/context" \
  "$WORKSPACE_ROOT/.workspace/outputs" \
  "$WORKSPACE_ROOT/.workspace/sessions" \
  "$WORKSPACE_ROOT/.claude" \
  "$WORKSPACE_ROOT/.vscode"
```

[ASSUMED — multi-arg mkdir syntax; standard bash]

### Workspace Name Validation

```bash
NAME="$USER_ANSWER"
if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*$ ]] || [[ "$NAME" == *".."* ]] || [[ "$NAME" == *"/"* ]]; then
  echo "Invalid workspace name. Use lowercase letters, numbers, and hyphens only (e.g. my-project)."
  # Stop or re-ask
fi
```

[ASSUMED — regex pattern; carry-forward from Phase 3 with leading-letter requirement added]

### Existence Check Before Scaffold

```bash
# Check if workspace root already exists before scaffolding
test -d "$WORKSPACE_ROOT" && echo "EXISTS" || echo "NEW"
```

[VERIFIED: same pattern as Phase 3 skill existence check in SKILL.md]

---

## What Carries Forward from Phase 3

| Pattern | Phase 3 Source | Phase 4 Adaptation |
|---------|---------------|-------------------|
| Empty-args / guard check | Stage 1 | Not needed — workspace-create has no required `$ARGUMENTS`; guard is optional (may check CWD instead) |
| 4-backtick preview fence | Stage 7 | Apply if scaffold plan preview contains triple-backtick fences |
| Chat-level "Write it?" gate | Stage 7 | "Shall I create all these? Reply yes or describe changes." |
| Validate → mkdir -p → Write order | Stage 8 | Multiple dirs; all mkdir first, then all Writes |
| `^[a-z0-9]+(-[a-z0-9]+)*$` name validation | Stage 8 | Tighten to require leading letter: `^[a-z][a-z0-9-]*$` |
| Path traversal rejection (`/`, `..`, `\`) | Stage 8 | Same |
| Confirmation message in chat | Stage 9 | "Workspace <name> created at ./<name>/." |
| AskUserQuestion ≤3 explicit options | All stages | Only for fixed binary choices — most Phase 4 questions are chat-freeform |
| Overwrite warning before scaffold | Security section | Check if `<workspace-name>/` exists; warn if so |

---

## Runtime State Inventory

Phase 4 is a greenfield scaffolder — it creates new state, does not rename or migrate. No runtime state inventory needed.

**Confirmed:** The skill creates files at a user-chosen CWD-relative location. No existing data is renamed or migrated.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Bash | All mkdir calls | ✓ | git-bash 5.x | — |
| Write tool | All file creation | ✓ (in allowed-tools) | — | — |
| `$(pwd)` command | Workspace root resolution | ✓ | — | Hardcode or ask user for absolute path |
| `date +%Y-%m-%d` | CLAUDE.md `{{CREATED_DATE}}` | ✓ (git-bash) | — | Use `2026-04-29` static fallback if date fails |

[VERIFIED: Bash and Write tool availability confirmed from stub frontmatter + Phase 1 settings.local.json.example showing `Bash(mkdir:**)` is allowed]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Workspace root is created as a new subdirectory of CWD where Claude Code was invoked (Option A) | Architecture Patterns, Code Examples | If wrong directory, user gets workspace in unexpected location; may need to move files manually |
| A2 | Approach A (separate CLAUDE.md template file) is better than inline generation | Standard Stack | If template file approach has runtime Read permission issues, inline is fallback; minimal risk |
| A3 | `$(pwd)` in git-bash on Windows returns a usable absolute path for Write tool | Code Examples | If Write tool doesn't accept `/d/repos/...` Unix-style paths, will need `$PWD` or `cmd /c cd` translation |
| A4 | `.claude/settings.local.json` should be written inside the workspace (useful default) | .claude/ and .vscode/ section | If user doesn't want it, they delete it; risk is minimal |
| A5 | Workspace name validation regex `^[a-z][a-z0-9-]*$` is appropriate | Pattern 5 | If too restrictive (e.g., numeric-only names), user gets re-prompted unnecessarily |
| A6 | Per-repo purpose should be collected with one chat question per repo (iterative) | Architecture Patterns | If user has 10 repos, this becomes 10 questions; may need a batched "list them all" variant for large workspaces |
| A7 | Existing workspace detection: check if `<workspace-name>/` dir exists; warn + ask before proceeding | Edge Cases | If not implemented, scaffold silently overwrites; WORK-03 doesn't specify behavior |
| A8 | `.vscode/` gets only `.gitkeep` (no content); user adds their own settings | Edge Cases | User may expect `settings.json` or `extensions.json` pre-populated; not required by WORK-04 |
| A9 | CLAUDE.md template uses `{{DOUBLE_BRACE}}` marker syntax | CLAUDE.md Template Design | Any marker syntax works at runtime since Claude is doing string substitution; aesthetic only |
| A10 | `date +%Y-%m-%d` works in git-bash on Windows to get current date | Code Examples | If Bash date command differs on Windows, fallback to asking Claude to insert today's date as text |

---

## Phase Requirements Mapping

<phase_requirements>

| ID | Description | Research Support |
|----|-------------|------------------|
| WORK-01 | User can invoke `/workspace-create` to start a guided workspace setup interview | Empty-args not required; skill invokes directly into interview flow. Pattern: chat-freeform questions, not AskUserQuestion for variable inputs |
| WORK-02 | Skill interviews user capturing: workspace name, repos list, per-repo purpose, overall workspace goal | 4-5 chat-level questions covering all required data points; iterative per-repo loop for variable repo counts |
| WORK-03 | Skill scaffolds full `.workspace/` directory structure: refs/, docs/, logs/, scratch/, context/, outputs/, sessions/ | Single Bash block with mkdir -p for all 7 subdirs + .claude/ + .vscode/; validate → mkdir → Write sequence |
| WORK-04 | Skill creates `.claude/` and `.vscode/` directories at workspace root alongside `.workspace/` | Included in the same mkdir -p batch; minimum content is empty dir or .gitkeep |
| WORK-05 | Skill generates a fully populated `CLAUDE.md` at workspace root derived from interview answers — no stubs, no unfilled placeholders | Template file with `{{MARKER}}` replacement; required markers re-asked if blank; optional markers get fallback strings; 200-line guard |
| WORK-06 | Skill creates a one-line README in each `.workspace/` subdirectory explaining its purpose | 7 Write calls, one per subdir; fixed one-line content per README (not derived from interview) |

</phase_requirements>

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Structural grep (bash) + manual UAT — no automated test runner for skill bodies |
| Config file | None — same pattern as Phases 2 and 3 |
| Quick run command | `grep -c "WORKSPACE" skills/workspace-create/SKILL.md` (structural check) |
| Full suite command | Manual invocation: `/workspace-create` in a live Claude Code session |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WORK-01 | Skill body present and invocable | structural-grep | `grep -c "workspace" skills/workspace-create/SKILL.md` | Wave 0 (stub exists) |
| WORK-02 | Interview questions for name, repos, purpose, goal present | structural-grep | `grep -c "repo" skills/workspace-create/SKILL.md` | Wave 0 |
| WORK-03 | All 7 .workspace/ subdirs appear in mkdir instruction | structural-grep | `grep -c "\.workspace" skills/workspace-create/SKILL.md` | Wave 0 |
| WORK-04 | .claude/ and .vscode/ in mkdir instruction | structural-grep | `grep -c "\.claude\|\.vscode" skills/workspace-create/SKILL.md` | Wave 0 |
| WORK-05 | Template file exists and marker replacement instruction present | structural-grep | `test -f skills/workspace-create/templates/CLAUDE.md.template && echo EXISTS` | Wave 0 gap |
| WORK-05 | 200-line guard instruction present | structural-grep | `grep -c "200" skills/workspace-create/SKILL.md` | Wave 0 |
| WORK-06 | README.md write instruction for each subdir | structural-grep | `grep -c "README" skills/workspace-create/SKILL.md` | Wave 0 |
| ALL | End-to-end workspace creation works | manual-UAT | `/workspace-create` in live session; verify directory tree + CLAUDE.md populated | Manual |

### Wave 0 Gaps

- [ ] `skills/workspace-create/templates/CLAUDE.md.template` — must be created in Phase 4; currently only `.gitkeep` exists
- [ ] No other test infrastructure gaps — SKILL.md stub exists; structural greps run inline

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Local file write, no auth |
| V3 Session Management | No | Stateless skill invocation |
| V4 Access Control | Partial | Write permission gated by `settings.local.json` allow-list from Phase 1 |
| V5 Input Validation | Yes | Workspace name: regex + path traversal rejection before any mkdir/Write |
| V6 Cryptography | No | No secrets, no encryption needed |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via workspace name | Tampering | Reject names containing `/`, `..`, `\`; regex `^[a-z][a-z0-9-]*$` gates all mkdir calls |
| Overwrite existing workspace without warning | Tampering | Check if `<workspace-name>/` exists before scaffold; warn + confirm before proceeding |
| CLAUDE.md stub leakage | Information Disclosure | All `{{MARKERS}}` must be replaced before Write; final-checks checklist verifies |
| Scaffold to unexpected directory | Elevation of Privilege | Resolve WORKSPACE_ROOT once as absolute path; validate it looks like a subdirectory of CWD, not root or home |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| AskUserQuestion for all interview inputs | Mixed: chat-freeform for variable-length, AskUserQuestion for fixed choices only | Phase 4 design | AskUserQuestion's 4-option limit cannot carry repo lists or purpose strings |
| `~` for global writes | `$USERPROFILE` (Phase 3) | v2.1.79+ Issue #30553 | Not applicable to Phase 4 — workspace writes are CWD-relative, not global |
| Hard-coded template in skill body | Separate template file loaded via `${CLAUDE_SKILL_DIR}/templates/` | Phase 4 design | Keeps SKILL.md readable; template maintainable independently |

---

## Sources

### Primary (HIGH confidence)

- `skills/workspace-create/SKILL.md` stub — frontmatter fields confirmed final; comments reveal template loading intent
- `skills/workspace-create/templates/` — verified `.gitkeep` only; template file does not yet exist
- `skills/skill-create/SKILL.md` — carry-forward patterns: validate→mkdir→Write sequence, overwrite warning, chat "Write it?" gate, name validation
- `skills/improve-prompt/SKILL.md` — instruction body structure: guard, how-to sections, worked example, final checks
- `.planning/phases/03-skill-creator-skill/03-RESEARCH.md` — pitfalls 1-6 validated, all applicable
- `.planning/REQUIREMENTS.md` — WORK-01 through WORK-06 full text
- `./CLAUDE.md` (project) — AskUserQuestion 4-option limit, Windows path constraint, 200-line CLAUDE.md cap, workspace-create description

### Secondary (MEDIUM confidence)

- `.planning/STATE.md` — Issue #30553 (Windows tilde), Issue #36497 (permission regression), AskUserQuestion limit confirmed
- `.planning/PROJECT.md` — workspace structure context; `.workspace/` isolation convention described

### Tertiary (LOW confidence)

- None — all material sourced from local codebase files read this session.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — frontmatter final in stub; tools verified; carry-forward patterns from Phases 2 and 3
- Architecture: MEDIUM — CWD-based workspace root is assumed, not locked; CLAUDE.md template design is assumed
- Pitfalls: HIGH — most are carry-forwards from Phase 3 research or direct constraint derivations
- Validation: HIGH — same structural-grep + manual-UAT pattern used successfully in Phases 2 and 3
- Open design questions: LOW — A1, A3, A6 in particular need planner or user confirmation

**Research date:** 2026-04-29
**Valid until:** Stable within Phase 4 timeline. Skill platform constraints change only with Claude Code releases.
