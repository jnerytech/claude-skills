---
name: skill-create
description: "Interviews the user about trigger, tools, output, and guards, then generates a new Claude Code skill and writes it to ~/.claude/skills/<name>/SKILL.md. Manual invocation only via /skill-create <description>."
argument-hint: [skill-description]
allowed-tools: [Read, Glob, Grep, Write, Bash]
disable-model-invocation: true
model: opus
---

# Skill Create

The user invoked this with: $ARGUMENTS

## Stage 1 — When to act

If `$ARGUMENTS` is empty or contains only whitespace, output exactly:

> Provide a description of the skill you want to create, for example:
> `/skill-create a slash command that summarizes git logs`

Then stop — do not attempt an interview, do not ask a clarifying question.

Otherwise proceed to Stage 2.

## Stage 2 — Read reference documentation

Before asking any interview question, read:

```
${CLAUDE_SKILL_DIR}/references/extend-claude-with-skills.md
```

This is a mandatory numbered step — not implied behavior. Reading this file first grounds every option label and frontmatter field name in the interview on the actual platform spec. Do not skip it.

After the interview is complete (Stage 4), you will conditionally read additional reference files based on what the interview revealed (Stage 5).

## Stage 3 — Infer and confirm the skill name

Infer a kebab-case name from `$ARGUMENTS`. Propose it before any interview question:

> "I'd name this `<inferred-name>` — change it?"

Use AskUserQuestion with exactly 2 explicit options (platform appends "Other" → total = 3, within limit):
- "Yes, use this name"
- "Enter a different name"

If the user selects "Enter a different name" or "Other", accept their freeform input as the name.

The name is confirmed here and does not change again — not at the preview step, not after confirmation.

## Stage 4 — Adaptive interview

Ask about the four required topics in order. Skip a topic only when `$ARGUMENTS` unambiguously answers it. Each AskUserQuestion uses ≤3 explicit options — the platform appends "Other" automatically, so the total must not exceed 4.

**Topic 1 — Trigger pattern**
Question: "Should Claude invoke this skill automatically, or only when you type /<name>?"
Options (≤3 explicit):
- "User-only slash command (Recommended)" — sets `disable-model-invocation: true`; best for side-effectful workflows like file writes and interviews
- "Claude auto-invokes" — no restriction; best for reference or knowledge skills
- "Propose based on description" — Claude selects the appropriate setting from context

**Topic 2 — Tools needed**
Question: "Which tools will this skill use?"
Options (≤3 explicit):
- "Read/Write/Bash (file operations)" — for skills that read files, write output, or run commands
- "Read/Glob/Grep (search only)" — for skills that explore the codebase without writing
- "Chat output only (no tools)" — for skills that reason and reply in chat with no tool calls

**Topic 3 — Output destination**
Question: "Where does this skill send its output?"
Options (≤3 explicit):
- "Chat only (no files written)" — skill replies in chat; no Write or Bash needed
- "File write (creates/modifies files)" — adds Write and Bash (for mkdir) to allowed-tools
- "Both — chat output plus file write" — combines the above

**Topic 4 — Edge cases/guards**
Question: "How should this skill handle empty or bad input?"
Options (≤3 explicit):
- "Output usage message and stop (Recommended)" — same guard pattern as /improve-prompt
- "Ask for clarification" — use AskUserQuestion to gather missing context before proceeding
- "Apply a default and proceed" — fill in sensible defaults and continue without blocking

## Stage 5 — Conditional reference reads

After the interview is complete, read additional reference docs only when the interview revealed a corresponding need. Do not read all four files unconditionally — load only what applies:

- If Topic 1 answer indicates hook-based trigger or Topic 2 answer includes Bash hook operations:
  Read `${CLAUDE_SKILL_DIR}/references/automate-workflows-with-hooks.md`
- If Topic 3 answer indicates subagent dispatch or fork-based output:
  Read `${CLAUDE_SKILL_DIR}/references/create-custom-subagents.md`
- If the skill description or interview answers mention CI, scripts, or programmatic invocation:
  Read `${CLAUDE_SKILL_DIR}/references/run-claude-code-programmatically.md`

If none of these conditions apply, proceed to Stage 6 with only the core reference already read.

## Stage 6 — Generate the SKILL.md content

Build the full SKILL.md in memory — do not write to disk yet. Use this frontmatter template:

```yaml
---
name: <kebab-case name confirmed in Stage 3>
description: "<what it does and when to use it — front-load the key use case>"
argument-hint: [<hint if applicable>]
allowed-tools: [<tools derived from Topic 2 and Topic 3 interview answers>]
disable-model-invocation: <true from Topic 1 if user-only, omit or false if Claude auto-invokes>
---
```

Write the instruction body using the same structure as `/improve-prompt`:
- `## When to act` guard (based on Topic 4 answer)
- `## How to [verb]` section(s) with numbered steps
- A worked example (use 4-backtick outer fence if body contains triple-backtick fences)
- `## Final checks before responding` numbered checklist

Ground every frontmatter field name and capability description in what you read from `extend-claude-with-skills.md` in Stage 2.

## Stage 7 — Preview the generated skill

First, check if the target path already exists:

```bash
test -f "$USERPROFILE/.claude/skills/<name>/SKILL.md" && echo "EXISTS" || echo "NEW"
```

If the result is EXISTS, output the following warning before the preview block:

> A skill named `<name>` already exists at $USERPROFILE/.claude/skills/<name>/SKILL.md. Overwrite?

Then display the full generated SKILL.md (frontmatter + body) inside a 4-backtick outer fence:

````markdown
---
name: <name>
...
---

[body]
````

(The 4-backtick outer fence prevents inner triple-backtick fences in the body from terminating the preview block. This is only how the preview is encoded in these instructions — the actual file content uses standard triple-backtick fences.)

Then ask in chat (not via AskUserQuestion):

> Write it? Reply 'yes' to write or describe changes.

Wait for the user to reply before proceeding to Stage 8. Do not use AskUserQuestion here — a chat-level reply is sufficient after a long interview.

## Stage 8 — Write the skill

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
   Use `$USERPROFILE`, not `~`. The Write tool does not expand `~` on Windows (confirmed Issue #30553). `$USERPROFILE` is reliably exported in git-bash on Windows.

3. **Write the file**:
   Write the generated SKILL.md content (from Stage 6) to `$SKILL_DIR/SKILL.md`.

## Stage 9 — Confirm

Output in chat:

> Written to $USERPROFILE/.claude/skills/<name>/SKILL.md. Restart Claude Code to load the skill.

## Worked example — end-to-end skill creation

When the user runs `/skill-create a skill that summarizes git log output`, the full flow looks like this:

- **Stage 1:** `$ARGUMENTS` = "a skill that summarizes git log output" — not empty, proceed
- **Stage 2:** Read `${CLAUDE_SKILL_DIR}/references/extend-claude-with-skills.md`
- **Stage 3:** Propose `git-log-summary` — user selects "Yes, use this name"
- **Stage 4:** Topic 1 → "User-only slash command"; Topic 2 → "Read/Glob/Grep (search only)"; Topic 3 → "Chat only"; Topic 4 → "Output usage message and stop"
- **Stage 5:** No hook/subagent/programmatic needs detected — no additional refs read
- **Stage 6:** Generate SKILL.md with `name: git-log-summary`, `disable-model-invocation: true`, `allowed-tools: [Read, Glob, Grep]`
- **Stage 7:** Check path — NEW. Display preview:

````markdown
---
name: git-log-summary
description: "Summarizes recent git log output as a concise bullet list. Use when you want a readable summary of recent commits."
argument-hint: [number-of-commits]
allowed-tools: [Read, Glob, Grep]
disable-model-invocation: true
---

# Git Log Summary

The user invoked this with: $ARGUMENTS

## When to act

If `$ARGUMENTS` is empty or contains only whitespace, output:

> Provide the number of commits to summarize, for example: `/git-log-summary 20`

Then stop.

## How to summarize

Run `git log --oneline -${ARGUMENTS:-10}` and present each commit as a bullet:
`- <hash> <message>`
````

(The 4-backtick outer fence above is only how this example is encoded inside SKILL.md so the inner triple-backtick fences in the body don't terminate the preview block. Your actual preview output uses the same 4-backtick encoding.)

Ask: "Write it? Reply 'yes' to write or describe changes."

- **Stage 8:** Validate `git-log-summary` passes `^[a-z0-9]+(-[a-z0-9]+)*$`; run:
  ```bash
  mkdir -p "$USERPROFILE/.claude/skills/git-log-summary"
  ```
  Write to `$USERPROFILE/.claude/skills/git-log-summary/SKILL.md`
- **Stage 9:** "Written to $USERPROFILE/.claude/skills/git-log-summary/SKILL.md. Restart Claude Code to load the skill."

## Final checks before writing

Before executing the write step (Stage 8), confirm:
1. Name is confirmed (Stage 3) and validated (`^[a-z0-9]+(-[a-z0-9]+)*$` — no `/`, `..`, or `\`).
2. `extend-claude-with-skills.md` was read before the first AskUserQuestion call (Stage 2 ran before Stage 4).
3. All four interview topics (trigger, tools, output, guards) were covered or consciously skipped because `$ARGUMENTS` answered them.
4. Each AskUserQuestion call used ≤3 explicit options.
5. Generated SKILL.md was shown in a 4-backtick fenced preview before writing.
6. User confirmed with "yes" or equivalent in chat.
7. Name was validated with regex + path-traversal check before mkdir.
8. `mkdir -p` ran before the Write call.
9. `$USERPROFILE` was used — not `~`.
