---
name: workspace-create
description: "Guides a workspace setup interview and scaffolds .workspace/, .claude/, .vscode/ directories with a fully populated CLAUDE.md. Use when the user invokes /workspace-create or asks to 'set up a workspace', 'create a workspace', or 'scaffold a new workspace'. Do NOT use for setting up individual project repos."
allowed-tools: [Read, Write, Bash]
disable-model-invocation: true
---

# Workspace Create

The user invoked this with: $ARGUMENTS

## Stage 1: Check for workspace name hint

```
The user invoked this with: $ARGUMENTS

If $ARGUMENTS is non-empty and not only whitespace:
  1. Validate the proposed name immediately:
     ```bash
     NAME="<$ARGUMENTS>"
     if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*$ ]] || [[ "$NAME" == *".."* ]] || \
        [[ "$NAME" == *"/"* ]] || [[ "$NAME" == *"\\"* ]]; then
       echo "INVALID"
     else
       echo "VALID"
     fi
     ```
     If INVALID: output "The name `<$ARGUMENTS>` is not valid. Workspace names must
     match `^[a-z][a-z0-9-]*$` with no path separators." and stop.
  2. Only if VALID: Output "I'll name this workspace `<$ARGUMENTS>` — change it?"
     Wait for the user's reply before proceeding to Stage 2.
     - If the user says "yes", "ok", or equivalent: proceed to Stage 2 using the proposed name
       (skip Q1 in Stage 2 — name is confirmed).
     - If the user provides a different name: treat that response as the new proposed name,
       validate it per the Q1 Bash block, then proceed to Stage 2.

If $ARGUMENTS is empty or whitespace, proceed directly to Stage 2 with no proposed name.
```

## Stage 2: Conduct workspace interview

Ask each question in chat (NOT via AskUserQuestion — these are freeform inputs that exceed AskUserQuestion's 4-option limit). Wait for the user's reply before asking the next question.

**Q1 — Workspace name** (skip if Stage 1 proposed a name and user confirmed it):
> "What should I name this workspace? Use lowercase letters, numbers, and hyphens only (e.g. `my-project`). This becomes the directory name."

Validate name immediately after receiving the answer: run in Bash:
```bash
NAME="<user-answer>"
if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*$ ]] || [[ "$NAME" == *".."* ]] || [[ "$NAME" == *"/"* ]] || [[ "$NAME" == *"\\"* ]]; then
  echo "INVALID"
else
  echo "VALID"
fi
```
If INVALID: explain the constraint and re-ask Q1. Do not proceed until validation passes.

**Q2 — Repos to include:**
> "Which repos will this workspace include? List them separated by commas or newlines."

**Q3 — Per-repo purpose (iterative):**
For each repo named in Q2, ask in chat:
> "What is the purpose of `<repo-name>`?"

Collect one answer per repo. If the user listed 3 repos, ask 3 separate questions.

**Q4 — Overall workspace goal:**
> "In 1-3 sentences, what is the overall goal of this workspace?"

If the answer is blank or less than 5 words, re-ask: "Could you describe the goal in a bit more detail? This becomes the opening paragraph of your CLAUDE.md."

**Q5 — Primary stack (optional):**
> "What is the primary language or stack? (Press Enter or type 'skip' to leave blank)"

If blank or 'skip', record as empty string — Stage 7 will use the fallback "Not specified".

## Stage 3: Show scaffold plan preview

After all interview answers are collected, show the full scaffold plan in chat before writing anything. Use a 4-backtick outer fence for the preview block (prevents inner triple-backtick fences from terminating the preview):

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

Then ask in chat (not via AskUserQuestion):
> "Shall I create all these files? Reply 'yes' to proceed or describe changes."

Wait for the user to reply before proceeding to Stage 4. If the user describes changes, incorporate them and show the updated preview. Do not proceed until the user says 'yes' or equivalent.

## Stage 4: Check for existing workspace

Before any mkdir or Write:
```bash
WORKSPACE_ROOT="$(pwd)/<validated-name>"
test -d "$WORKSPACE_ROOT" && echo "EXISTS" || echo "NEW"
```

If the result is EXISTS, output the following warning in chat:
> "A directory named `<name>` already exists at `<WORKSPACE_ROOT>`. Proceeding will add files into it without deleting what's there. Continue?"

Wait for the user to confirm before proceeding. If they decline, stop.

## Stage 5: Scaffold directories

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

Do NOT use relative paths. Always use `$WORKSPACE_ROOT` (absolute via `$(pwd)`). Never use `$USERPROFILE` — this workspace is CWD-relative, not global.

## Stage 6: Write README files

Write exactly 7 README.md files — one per .workspace/ subdirectory. Use Write tool for each. The content is a single line:

- `$WORKSPACE_ROOT/.workspace/refs/README.md` → `Reference materials and external resources for this workspace.`
- `$WORKSPACE_ROOT/.workspace/docs/README.md` → `Documentation files and guides for workspace projects.`
- `$WORKSPACE_ROOT/.workspace/logs/README.md` → `Session logs and activity records.`
- `$WORKSPACE_ROOT/.workspace/scratch/README.md` → `Temporary scratch space for experiments and drafts.`
- `$WORKSPACE_ROOT/.workspace/context/README.md` → `Persistent context files shared across sessions.`
- `$WORKSPACE_ROOT/.workspace/outputs/README.md` → `Generated outputs and artifacts from Claude sessions.`
- `$WORKSPACE_ROOT/.workspace/sessions/README.md` → `Per-session working directories.`

## Stage 7: Generate CLAUDE.md content

Read the template file:
```
${CLAUDE_SKILL_DIR}/templates/CLAUDE.md.template
```

This is a mandatory Read step — not implied behavior. The template contains 6 markers. Replace each marker with the interview answer:

| Marker | Source | Rule |
|--------|--------|------|
| `{{WORKSPACE_NAME}}` | Q1 answer | Required — re-ask if blank |
| `{{WORKSPACE_GOAL}}` | Q4 answer | Required — re-ask if blank |
| `{{REPO_MAP}}` | Q2+Q3 answers | Format each as a table row: `\| <repo> \| <purpose> \|` — one row per repo. Fallback if no repos: `No repos specified` |
| `{{STACK}}` | Q5 answer | Fallback: `Not specified` |
| `{{CREATED_DATE}}` | Bash `date +%Y-%m-%d` | Fallback: use today's date as literal string if Bash fails |
| `{{CONVENTIONS}}` | Derived: combine stack + goal into 1-2 practical rules | Fallback: `Follow standard conventions for the stack` |

After replacing all markers, verify the result line count:
```bash
echo "<generated-content>" | wc -l
```
If the count is >= 195, trim the `{{REPO_MAP}}` rows first (summarize multiple purposes on one row), then shorten the `{{CONVENTIONS}}` section, until the count is < 195. Only then write.

Write the populated content to `$WORKSPACE_ROOT/CLAUDE.md`.

**Zero tolerance for unreplaced markers:** Before writing, scan the generated content for any remaining `{{` patterns. If any are found, replace them with the appropriate fallback. Never write `{{MARKER}}` to the final CLAUDE.md.

## Stage 8: Write .claude/settings.local.json

Write a minimal settings file inside the workspace's .claude directory:
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

This mirrors the Phase 1 template and is a useful default for the workspace. It is workspace-local — it does NOT affect `~/.claude/`.

## Stage 9: Confirm

Output in chat:
> "Workspace `<name>` created at `./<name>/`. CLAUDE.md populated. Open it to review."

## Worked example — end-to-end workspace creation

When the user runs `/workspace-create my-apis`, the full flow looks like this:

- **Stage 1:** `$ARGUMENTS` = "my-apis" — propose name "my-apis", user confirms
- **Stage 2:** Q2 → "api-gateway, billing-service"; Q3 → "api-gateway: Routes all traffic", "billing-service: Handles subscriptions"; Q4 → "Track and debug API + billing interactions across services."; Q5 → "TypeScript, Node.js"
- **Stage 3:** Show preview tree with CLAUDE.md header; user replies "yes"
- **Stage 4:** `test -d "$(pwd)/my-apis"` → NEW; proceed
- **Stage 5:** Run single mkdir batch creating all 9 directories
- **Stage 6:** Write 7 README files with one-line content
- **Stage 7:** Read `${CLAUDE_SKILL_DIR}/templates/CLAUDE.md.template`; replace markers:
  - `{{WORKSPACE_NAME}}` → `my-apis`
  - `{{WORKSPACE_GOAL}}` → `Track and debug API + billing interactions across services.`
  - `{{REPO_MAP}}` → two separate table rows (one per line):
      | api-gateway | Routes all traffic |
      | billing-service | Handles subscriptions |
  - `{{STACK}}` → `TypeScript, Node.js`
  - `{{CREATED_DATE}}` → `2026-04-29` (from Bash)
  - `{{CONVENTIONS}}` → `Use async/await consistently. Avoid mutating shared state across services.`
  - Verify: `wc -l` → 58 lines (< 195 — no trimming needed)
  - Verify: no `{{` patterns remain
  - Write to `my-apis/CLAUDE.md`
- **Stage 8:** Write `my-apis/.claude/settings.local.json`
- **Stage 9:** "Workspace `my-apis` created at `./my-apis/`. CLAUDE.md populated. Open it to review."

## Pre-mkdir checks (before Stage 5)

1. Workspace name validated with `^[a-z][a-z0-9-]*$` — no `/`, `..`, or `\` in name.
2. All 5 interview questions answered (name, repos, per-repo purpose, goal, stack — or blank/skip recorded for Q5).
3. `{{WORKSPACE_NAME}}` and `{{WORKSPACE_GOAL}}` are non-empty (re-asked if needed).
4. `{{STACK}}` has either a user-provided value or the fallback "Not specified".
5. `{{REPO_MAP}}` has either formatted table rows or the fallback "No repos specified".
6. `{{CONVENTIONS}}` has either a derived value or the fallback "Follow standard conventions for the stack".
7. Scaffold plan preview shown to user; user replied 'yes' or equivalent.
8. Existing workspace check ran before mkdir; user confirmed if EXISTS.
9. All 9 `mkdir -p` paths use `$WORKSPACE_ROOT` (absolute) — no relative paths, no `$USERPROFILE`.

## Pre-Write checks (before Stage 7 Write call)

10. All 6 markers replaced in generated CLAUDE.md; zero `{{` patterns remain.
11. `wc -l` on generated CLAUDE.md content is < 195 before Write.
12. All Write paths use `$WORKSPACE_ROOT` — not `~`, not `$USERPROFILE`, not a hardcoded path.
