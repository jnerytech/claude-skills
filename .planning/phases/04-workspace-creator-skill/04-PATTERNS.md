# Phase 4: Workspace Creator Skill - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 2
**Analogs found:** 1 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `skills/workspace-create/SKILL.md` | skill (instruction body) | interview → validate → scaffold (CRUD write) | `skills/skill-create/SKILL.md` | exact |
| `skills/workspace-create/templates/CLAUDE.md.template` | template (marker file) | transform (variable substitution) | none | no analog |

---

## Pattern Assignments

### `skills/workspace-create/SKILL.md` (skill, interview-driven scaffold)

**Analog:** `skills/skill-create/SKILL.md`

**Overall stage skeleton** (lines 9–171 of analog) — numbered `##` sections establish the linear sequence to follow:

```
# When to act        → guard on $ARGUMENTS (adapt: optional, not required)
# Read reference doc → ${CLAUDE_SKILL_DIR}/... load (adapt: load CLAUDE.md.template here)
# Infer / confirm    → name confirmation step (adapt: chat-freeform, not AskUserQuestion)
# Adaptive interview → 4 topics via AskUserQuestion (adapt: chat-freeform for variable inputs)
# Conditional reads  → only-if-needed reference reads (adapt: may not apply to Phase 4)
# Generate content   → build output in memory before writing
# Preview            → 4-backtick fence + chat "Write it?" gate
# Write              → validate → mkdir → Write (exact order, adapt paths)
# Confirm            → single chat confirmation message
# Worked example     → full end-to-end walkthrough
# Final checks       → numbered checklist before write
```

**Guard pattern** (analog lines 13–22):
```markdown
## When to act

If `$ARGUMENTS` is empty or contains only whitespace, output exactly:

> Provide a description of the skill you want to create, for example:
> `/skill-create a slash command that summarizes git logs`

Then stop — do not attempt an interview, do not ask a clarifying question.

Otherwise proceed to Stage 2.
```

**Deviation for Phase 4:** `$ARGUMENTS` is optional (no `argument-hint` in stub). Adapt guard to: "If `$ARGUMENTS` is non-empty, treat it as the proposed workspace name and confirm with the user before the interview begins. Then proceed to Stage 2."

**Template-load pattern** (analog lines 24–34):
```markdown
## Read reference documentation

Before asking any interview question, read:

```
${CLAUDE_SKILL_DIR}/references/extend-claude-with-skills.md
```

This is a mandatory numbered step — not implied behavior.
```

**Adaptation for Phase 4:** Replace reference doc path with template path. Stage reads `${CLAUDE_SKILL_DIR}/templates/CLAUDE.md.template` before the scaffold write stage.

**BLOCKING DEPENDENCY:** This pattern requires Read tool access. Stub frontmatter is `allowed-tools: [Write, Bash]` — Read is NOT listed. Planner must decide:
- Approach A: Add `Read` to `allowed-tools` (frontmatter deviation, justified by stub comment on line 17)
- Approach B: Embed template inline in SKILL.md (no frontmatter change; SKILL.md becomes longer)
- Approach C: Load template via `bash cat` (Bash already allowed; awkward pattern)
See RESEARCH.md "Critical Open Design Questions Q2" for full decision tree.

**Preview + 4-backtick fence** (analog lines 119–146):
```markdown
## Preview the generated skill

First, check if the target path already exists:

```bash
test -f "$USERPROFILE/.claude/skills/<name>/SKILL.md" && echo "EXISTS" || echo "NEW"
```

If the result is EXISTS, output the following warning before the preview block:

> A skill named `<name>` already exists at $USERPROFILE/.claude/skills/<name>/SKILL.md. Overwrite?

Then display the full generated SKILL.md (frontmatter + body) inside a 4-backtick outer fence:

````markdown
[content]
````

Then ask in chat (not via AskUserQuestion):

> Write it? Reply 'yes' to write or describe changes.

Wait for the user to reply before proceeding to Stage 8.
```

**Adaptation for Phase 4:**
- Existence check path becomes: `test -d "$(pwd)/<workspace-name>" && echo "EXISTS" || echo "NEW"`
- Preview shows directory tree + first ~10 lines of CLAUDE.md, not a SKILL.md block
- Prompt: "Shall I create all these files? Reply 'yes' to proceed or describe changes."

**Validate → mkdir → Write sequence** (analog lines 148–165):
```markdown
## Write the skill

Execute in this exact order — validate first, mkdir second, Write third. Never reorder.

1. **Validate the name** before any file operation:
   - Name must match `^[a-z0-9]+(-[a-z0-9]+)*$`
   - Name must not contain `/`, `..`, or `\`
   If validation fails, output an error message and stop — do not run mkdir or Write.

2. **Create the directory** via Bash:
   ```bash
   SKILL_DIR="$USERPROFILE/.claude/skills/<validated-name>"
   mkdir -p "$SKILL_DIR"
   ```
   Use `$USERPROFILE`, not `~`.

3. **Write the file**:
   Write the generated SKILL.md content (from Stage 6) to `$SKILL_DIR/SKILL.md`.
```

**Adaptations for Phase 4 (four critical deviations — do not copy directly):**

1. **Name regex tightens.** Analog uses `^[a-z0-9]+(-[a-z0-9]+)*$` (allows numeric start). Phase 4 must use `^[a-z][a-z0-9-]*$` (requires leading letter — workspace name becomes a directory name).

2. **Path switches from global to CWD-relative.** Analog uses `$USERPROFILE/.claude/skills/<n>`. Phase 4 uses `$(pwd)/<workspace-name>`. Never use `$USERPROFILE` in Phase 4 scaffold paths.

3. **mkdir batch expands to 9 dirs.** Analog does a single mkdir. Phase 4 needs one Bash block creating all 9 directories at once (see RESEARCH.md "All mkdir -p Calls in One Bash Block"):
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

4. **Interview style flips from AskUserQuestion to chat-freeform.** Analog uses AskUserQuestion for all 4 interview topics (lines 51–81). Phase 4 MUST use chat-level questions for: workspace name, repo list, per-repo purpose, and overall goal — all are variable-length freeform inputs that exceed AskUserQuestion's 4-option limit. AskUserQuestion is reserved only for any fixed binary/ternary choice that arises (e.g., "include settings.local.json?").

**Confirm message pattern** (analog lines 167–171):
```markdown
## Confirm

Output in chat:

> Written to $USERPROFILE/.claude/skills/<name>/SKILL.md. Restart Claude Code to load the skill.
```

**Adaptation for Phase 4:**
```
> Workspace <name> created at ./<name>/. CLAUDE.md populated. Open it to review.
```

**Worked example structure** (analog lines 173–221) — planner must mirror this structure for Phase 4:
- Show sample interview answers for workspace name, 2-3 repos, their purposes, overall goal
- Show the directory tree the skill will create
- Show sample CLAUDE.md populated sections (not raw template)
- Show the chat gate question and user's "yes" response
- Show the mkdir Bash block and all Write calls

**Final checks list pattern** (analog lines 223–235):
```markdown
## Final checks before writing

Before executing the write step (Stage 8), confirm:
1. Name is confirmed (Stage 3) and validated (`^[a-z0-9]+(-[a-z0-9]+)*$` — no `/`, `..`, or `\`).
2. `extend-claude-with-skills.md` was read before the first AskUserQuestion call.
3. All four interview topics were covered or consciously skipped.
4. Each AskUserQuestion call used ≤3 explicit options.
5. Generated SKILL.md was shown in a 4-backtick fenced preview before writing.
6. User confirmed with "yes" or equivalent in chat.
7. Name was validated with regex + path-traversal check before mkdir.
8. `mkdir -p` ran before the Write call.
9. `$USERPROFILE` was used — not `~`.
```

**Adaptation for Phase 4** — replace content with Phase 4 equivalents:
1. Workspace name validated (`^[a-z][a-z0-9-]*$` — no `/`, `..`, or `\`)
2. All 5 interview questions answered (name, repos, per-repo purpose, goal, stack)
3. Required markers confirmed non-empty (`{{WORKSPACE_NAME}}`, `{{WORKSPACE_GOAL}}`)
4. Optional markers given fallback if blank (`{{STACK}}` → "Not specified")
5. Zero `{{VARIABLE}}` markers remain in final CLAUDE.md
6. CLAUDE.md line count verified < 200 before Write
7. Scaffold plan shown in preview; user confirmed with "yes"
8. Name validated before any mkdir or Write
9. All 9 `mkdir -p` calls ran in one Bash block before any Write
10. All Write paths use `$WORKSPACE_ROOT` (absolute) — no relative paths, no `$USERPROFILE`

---

### `skills/workspace-create/templates/CLAUDE.md.template` (template, transform)

**Analog:** None in codebase.

**Closest structural reference** (not a template, but shows a populated workspace-style CLAUDE.md in practice): `D:/repos/claude-skills/CLAUDE.md` — 45 lines, uses `## Section` headings, mixes tables and bullet lists, no frontmatter.

**Design source:** RESEARCH.md sections "CLAUDE.md Template Design", "Template Marker List", and ".workspace/ Subdirectory READMEs".

**Template skeleton to implement** (from RESEARCH.md lines 299–332):

```markdown
# {{WORKSPACE_NAME}}

{{WORKSPACE_GOAL}}

**Created:** {{CREATED_DATE}}

## Repositories

| Repo | Purpose |
|------|---------|
{{REPO_MAP}}

## Directory Map

| Directory | Purpose |
|-----------|---------|
| `.workspace/refs/` | Reference materials and external resources |
| `.workspace/docs/` | Documentation files and guides |
| `.workspace/logs/` | Session logs and activity records |
| `.workspace/scratch/` | Temporary scratch space for experiments |
| `.workspace/context/` | Persistent context files shared across sessions |
| `.workspace/outputs/` | Generated outputs and artifacts |
| `.workspace/sessions/` | Per-session working directories |

## Stack / Language

{{STACK}}

## Session Conventions

- Start each session by reviewing `.workspace/context/` for persistent notes
- Log session summaries to `.workspace/logs/`
- Place experimental work in `.workspace/scratch/` before promoting to a repo

## Constraints

{{CONVENTIONS}}
```

**Markers** (from RESEARCH.md lines 325–332):

| Marker | Populated From | Fallback |
|--------|---------------|----------|
| `{{WORKSPACE_NAME}}` | Q1 answer | Re-ask (required) |
| `{{WORKSPACE_GOAL}}` | Q4 answer | Re-ask (required) |
| `{{REPO_MAP}}` | Q2+Q3 rows: `\| repo \| purpose \|` per line | `No repos specified` |
| `{{STACK}}` | Q5 answer | `Not specified` |
| `{{CREATED_DATE}}` | `date +%Y-%m-%d` via Bash | Static `2026-04-29` if Bash fails |
| `{{CONVENTIONS}}` | Derived from stack + goal | `Follow standard conventions for the stack` |

**Line budget:** ~50–55 lines base + N repo rows. At 5 repos: ~60 lines. Well within 200-line hard limit.

---

## Shared Patterns

### 4-Backtick Preview Fence
**Source:** `skills/skill-create/SKILL.md` lines 129–141
**Apply to:** `skills/workspace-create/SKILL.md` scaffold plan preview stage

When the scaffold plan preview contains any triple-backtick fences (e.g., showing CLAUDE.md content), wrap the entire preview block in a 4-backtick outer fence. This prevents inner fences from terminating the preview block.

```markdown
````markdown
[scaffold tree and CLAUDE.md preview here]
````
```

### Chat-Level Confirmation Gate (not AskUserQuestion)
**Source:** `skills/skill-create/SKILL.md` lines 142–146
**Apply to:** `skills/workspace-create/SKILL.md` preview stage

```markdown
Then ask in chat (not via AskUserQuestion):

> Write it? Reply 'yes' to write or describe changes.

Wait for the user to reply before proceeding. Do not use AskUserQuestion here — a chat-level reply is sufficient after a long interview.
```

**Adaptation:** Replace prompt text with "Shall I create all these files? Reply 'yes' to proceed or describe changes."

### Validate → mkdir → Write Order (Never Reorder)
**Source:** `skills/skill-create/SKILL.md` lines 148–165
**Apply to:** `skills/workspace-create/SKILL.md` scaffold execution stage

The three-step order is non-negotiable:
1. Validate name with regex + path-traversal check — stop on failure
2. `mkdir -p` all parent directories
3. Write files

### AskUserQuestion ≤3 Explicit Options
**Source:** `skills/skill-create/SKILL.md` lines 46, 58, 65, 73, 79 (all AskUserQuestion calls use ≤3 explicit options; platform auto-appends "Other" as 4th)
**Apply to:** `skills/workspace-create/SKILL.md` — any AskUserQuestion call (rare in Phase 4; most questions are chat-freeform)

If any binary/ternary choice question uses AskUserQuestion, it must have ≤3 explicit options.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `skills/workspace-create/templates/CLAUDE.md.template` | template | transform (marker substitution) | No template-with-markers files exist in the codebase. Design from RESEARCH.md "CLAUDE.md Template Design" section (lines 299–332) and project's own `CLAUDE.md` as structural reference for a populated workspace doc. |

---

## Metadata

**Analog search scope:** `skills/` directory (all SKILL.md files)
**Files scanned:** 3 (workspace-create/SKILL.md stub, skill-create/SKILL.md, improve-prompt/SKILL.md)
**Pattern extraction date:** 2026-04-29
