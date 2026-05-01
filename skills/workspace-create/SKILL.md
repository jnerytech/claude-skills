---
name: workspace-create
description: "Use when the user wants to scaffold a workspace directory (.workspace/, .claude/, .vscode/) under ./[name]/ with a populated CLAUDE.md, or asks to 'criar workspace', 'novo workspace', 'montar workspace', 'inicializar workspace'. Asks the user a single batched chat question to gather goal, repos, and stack — no per-question round-trips. Manual invocation only via /workspace-create [workspace-name]."
argument-hint: [workspace-name]
allowed-tools: [Read, Write, Bash]
disable-model-invocation: true
model: haiku
---

# Workspace Create

The user invoked this with: $ARGUMENTS

## Stage 1 — Resolve and validate the workspace name

If `$ARGUMENTS` is non-empty and not only whitespace, treat it as the proposed name. Otherwise, ask in chat:

> What should I name this workspace? Use lowercase letters, numbers, and hyphens only (e.g. `my-project`).

Wait for the reply, then treat that as the proposed name.

Validate via Bash before continuing:

```bash
NAME="$ARGUMENTS"
if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*$ ]] || [[ "$NAME" == *".."* ]] || [[ "$NAME" == *"/"* ]] || [[ "$NAME" == *"\\"* ]]; then
  echo "INVALID"
else
  echo "VALID"
fi
```

If `INVALID`: output `The name \`<name>\` is not valid. Workspace names must match \`^[a-z][a-z0-9-]*$\` with no path separators.` and re-ask. Do NOT proceed to Stage 2 until validation returns `VALID`.

Confirm the resolved name with one chat line — no AskUserQuestion:

> I'll name this workspace `<name>` — change it? Reply 'yes' or supply a different name.

If the user supplies a different name, validate it the same way and loop. Otherwise proceed.

## Stage 2 — Batched workspace interview

Send a **single chat message** that asks for everything at once. Do not break the questions into separate turns. Do not use AskUserQuestion (the answers are freeform and exceed the 4-option limit anyway).

Output exactly:

> Tell me about workspace `<name>` in **one reply**:
>
> 1. **Goal** — 1-3 sentences describing what this workspace is for.
> 2. **Repos** — list the repos as `<repo-name>: <one-line purpose>` lines, one per repo. Reply `none` to skip.
> 3. **Stack** — primary language or framework. Reply `skip` to leave blank.
>
> Reply `minimal` to use defaults for everything (no repos, no stack, goal = "Workspace for `<name>`").

Wait for the user's reply. Parse it:

- **Goal** — required. If blank or under 5 words and the user did not say `minimal`, re-ask only that field with `Could you describe the goal in a bit more detail? It becomes the opening paragraph of CLAUDE.md.`
- **Repos** — split on newlines or commas. Each entry must contain a `:` separator. If absent, treat the entire entry as repo name with purpose `Not specified`. Empty list or `none` → fallback `| _none_ | No repos specified |`.
- **Stack** — single string. Empty or `skip` → fallback `Not specified`.

Record all three values for Stage 3.

## Stage 3 — Show scaffold preview

Display the scaffold plan inside a 4-backtick outer fence (prevents inner triple-backticks from terminating the block):

````markdown
Workspace: <name>
Root: ./<name>/

Directory structure:
<name>/
├── CLAUDE.md
├── .workspace/
│   ├── refs/          README: Reference materials and external resources for this workspace.
│   ├── docs/          README: Documentation files and guides for workspace projects.
│   ├── logs/          README: Session logs and activity records.
│   ├── scratch/       README: Temporary scratch space for experiments and drafts.
│   ├── context/       README: Persistent context files shared across sessions.
│   ├── outputs/       README: Generated outputs and artifacts from Claude sessions.
│   └── sessions/      README: Per-session working directories.
├── .claude/
└── .vscode/

CLAUDE.md preview:
# <name>
<first 1-2 sentences of workspace goal>
**Created:** <date>
...
````

Then ask in chat:

> Shall I create all these files? Reply 'yes' to proceed or describe changes.

Wait for the reply. If the user describes changes, incorporate them and re-show the preview. Do NOT proceed to Stage 4 until the user replies 'yes' or equivalent.

## Stage 4 — Check for existing workspace

Before any mkdir or Write:

```bash
WORKSPACE_ROOT="$(pwd)/<validated-name>"
test -d "$WORKSPACE_ROOT" && echo "EXISTS" || echo "NEW"
```

If `EXISTS`, warn:

> A directory named `<name>` already exists at `<WORKSPACE_ROOT>`. Proceeding will add files into it without deleting what's there. Continue?

Wait for confirmation. If the user declines, stop.

## Stage 5 — Scaffold directories

Run a single Bash block creating all 9 directories atomically:

```bash
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

Always use `$WORKSPACE_ROOT` (absolute via `$(pwd)`). Never use `$USERPROFILE` — this workspace is CWD-relative, not global.

## Stage 6 — Write README files

Write exactly 7 README.md files via Write — one per `.workspace/` subdirectory. Single-line content each:

- `$WORKSPACE_ROOT/.workspace/refs/README.md` → `Reference materials and external resources for this workspace.`
- `$WORKSPACE_ROOT/.workspace/docs/README.md` → `Documentation files and guides for workspace projects.`
- `$WORKSPACE_ROOT/.workspace/logs/README.md` → `Session logs and activity records.`
- `$WORKSPACE_ROOT/.workspace/scratch/README.md` → `Temporary scratch space for experiments and drafts.`
- `$WORKSPACE_ROOT/.workspace/context/README.md` → `Persistent context files shared across sessions.`
- `$WORKSPACE_ROOT/.workspace/outputs/README.md` → `Generated outputs and artifacts from Claude sessions.`
- `$WORKSPACE_ROOT/.workspace/sessions/README.md` → `Per-session working directories.`

## Stage 7 — Generate CLAUDE.md content

Read the template:

```
${CLAUDE_SKILL_DIR}/templates/CLAUDE.md.template
```

Mandatory Read step. The template contains 6 markers. Replace each with the interview values from Stage 2:

| Marker | Source | Fallback |
|---|---|---|
| `{{WORKSPACE_NAME}}` | Stage 1 name | required — already validated |
| `{{WORKSPACE_GOAL}}` | Stage 2 goal | re-ask if blank |
| `{{REPO_MAP}}` | Stage 2 repos | format each as `\| <repo> \| <purpose> \|` (one row per repo). If empty list: `\| _none_ \| No repos specified \|` |
| `{{STACK}}` | Stage 2 stack | `Not specified` |
| `{{CREATED_DATE}}` | `date +%Y-%m-%d` | today's date as literal string |
| `{{CONVENTIONS}}` | derive 1-2 practical rules from stack + goal | `Follow standard conventions for the stack` |

After replacing all markers, verify line count:

```bash
echo "<generated-content>" | wc -l
```

If ≥ 195, trim `{{REPO_MAP}}` rows first (summarize multiple purposes on one row), then shorten `{{CONVENTIONS}}`, until count is < 195. Only then write.

Write the populated content to `$WORKSPACE_ROOT/CLAUDE.md`.

**Zero tolerance for unreplaced markers:** before writing, scan for any remaining `{{` patterns. If any are found, replace with the appropriate fallback. NEVER write `{{MARKER}}` to the final CLAUDE.md. Do NOT proceed to Stage 8 until the marker scan returns zero matches.

## Stage 8 — Write `.claude/settings.local.json`

Write a minimal settings file:

```
$WORKSPACE_ROOT/.claude/settings.local.json
```

Content:

```json
{
  "permissions": {
    "allow": [
      "Write(.claude/**)"
    ]
  }
}
```

This is workspace-local. It does NOT affect `~/.claude/`.

## Stage 9 — Confirm

Output in chat:

> Workspace `<name>` created at `./<name>/`. CLAUDE.md populated. Open it to review.

## Worked example — end-to-end

User runs `/workspace-create my-apis`.

- **Stage 1:** `$ARGUMENTS` = "my-apis". Validation PASS. Confirm: "I'll name this workspace `my-apis` — change it?". User: "yes".
- **Stage 2:** Send batched ask. User replies in one message:

  > 1. Track and debug API + billing interactions across services.
  > 2. api-gateway: Routes all traffic
  >    billing-service: Handles subscriptions
  > 3. TypeScript, Node.js

  Parse: goal = "Track and debug…", repos = 2 entries, stack = "TypeScript, Node.js".

- **Stage 3:** Show preview tree + CLAUDE.md header. User: "yes".
- **Stage 4:** `test -d "$(pwd)/my-apis"` → NEW. Proceed.
- **Stage 5:** Run single mkdir batch (9 directories).
- **Stage 6:** Write 7 README files.
- **Stage 7:** Read template, replace markers:
  - `{{WORKSPACE_NAME}}` → `my-apis`
  - `{{WORKSPACE_GOAL}}` → `Track and debug API + billing interactions across services.`
  - `{{REPO_MAP}}` → two table rows
  - `{{STACK}}` → `TypeScript, Node.js`
  - `{{CREATED_DATE}}` → `2026-04-29`
  - `{{CONVENTIONS}}` → `Use async/await consistently. Avoid mutating shared state across services.`
  - `wc -l` → 58 lines (< 195). Write.
- **Stage 8:** Write `my-apis/.claude/settings.local.json`.
- **Stage 9:** "Workspace `my-apis` created at `./my-apis/`. CLAUDE.md populated. Open it to review."

## Critical Rules

- Workspace name MUST match `^[a-z][a-z0-9-]*$` with no `/`, `..`, or `\`. NEVER bypass validation.
- All paths MUST resolve via `$WORKSPACE_ROOT="$(pwd)/<validated-name>"` — absolute, CWD-relative. NEVER use `$USERPROFILE` (this is a project workspace, not a global skill). NEVER use `~`.
- `mkdir -p` MUST run before any Write call. Write tool does NOT create parent directories.
- Stage 3 preview confirmation MUST be received before any mkdir or Write. Do NOT proceed without explicit user 'yes'.
- The unreplaced-marker scan in Stage 7 MUST return zero matches before CLAUDE.md is written. NEVER write `{{MARKER}}` to disk.
- CLAUDE.md MUST be < 195 lines. NEVER write a longer file — trim repo rows and conventions first.
- Stage 8 writes ONLY to `$WORKSPACE_ROOT/.claude/settings.local.json` — NEVER touches `$USERPROFILE/.claude/` or any other global path.

## Pre-mkdir checks (before Stage 5)

1. Workspace name validated with `^[a-z][a-z0-9-]*$` — no `/`, `..`, or `\`.
2. Stage 2 batched ask answered (or `minimal` accepted).
3. `{{WORKSPACE_GOAL}}` non-empty (re-asked if needed).
4. `{{STACK}}` has a value or the fallback "Not specified".
5. `{{REPO_MAP}}` has formatted table rows or the fallback `| _none_ | No repos specified |`.
6. `{{CONVENTIONS}}` has a derived value or the fallback "Follow standard conventions for the stack".
7. Scaffold preview shown to user; user replied 'yes' or equivalent.
8. Existing-workspace check ran before mkdir; user confirmed if `EXISTS`.
9. All 9 `mkdir -p` paths use `$WORKSPACE_ROOT` (absolute) — no relative paths, no `$USERPROFILE`.

## Pre-Write checks (before Stage 7 Write call)

10. All 6 markers replaced in generated CLAUDE.md; zero `{{` patterns remain.
11. `wc -l` on generated CLAUDE.md content is < 195 before Write.
12. All Write paths use `$WORKSPACE_ROOT` — not `~`, not `$USERPROFILE`, not a hardcoded path.
