---
name: skill-create
description: "Generates a new Claude Code skill from a short description: infers name, tools, trigger, and guards from the description, shows a preview, and writes to ~/.claude/skills/<name>/SKILL.md after the user confirms. Manual invocation only via /skill-create <description>."
argument-hint: [skill-description]
allowed-tools: [Read, Write, Bash]
disable-model-invocation: true
model: opus
---

# Skill Create

The user invoked this with: $ARGUMENTS

## Stage 1 — When to act

If `$ARGUMENTS` is empty or contains only whitespace, output exactly:

> Provide a description of the skill you want to create, for example:
> `/skill-create a slash command that summarizes git logs`

Then stop — do not infer, do not ask a clarifying question.

Otherwise proceed to Stage 2.

## Stage 2 — Read the spec

Before any inference, read:

```
${CLAUDE_SKILL_DIR}/references/extend-claude-with-skills.md
```

Mandatory step. Every frontmatter field, default, and limit referenced below comes from this doc.

## Stage 3 — Infer settings from the description

Derive all of the following from `$ARGUMENTS` without asking the user. The user overrides any of these in the confirm step (Stage 5) by describing changes in chat.

### Name

Kebab-case, matches `^[a-z0-9]+(-[a-z0-9]+)*$`, ≤64 chars. Derive from the verb-object pair in the description (e.g. "summarizes git logs" → `git-log-summary`).

### Trigger

Default: **user-only** (`disable-model-invocation: true`).

Override only if the description explicitly says "Claude should auto-invoke", "automatic", or describes pure reference content with no side effects.

### Tools

Smallest set that covers the work:

| Verb cue in description | `allowed-tools` |
|---|---|
| "write", "create file", "scaffold", "save to" | `[Read, Write, Bash]` |
| "search", "find", "look up", "explore" | `[Read, Glob, Grep]` |
| "run", "execute", "shell command" | add `Bash` to whichever set above |
| "summarize", "explain", "rewrite", "review" with no file output | omit `allowed-tools` (chat-only) |

If ambiguous, default to chat-only. Tools can always be added in the confirm step.

### Output destination

Implicit from tools: has `Write` → file output; no `Write` → chat-only.

### Guard

Always emit the empty-input usage message in `## When to act` (same pattern as `/improve-prompt`).

### `argument-hint`

Add `[<thing>]` (square brackets per spec) when the description implies the skill needs an argument. Omit when the skill operates on session context only.

### Conditional reference reads

Load extra refs only when the inferred settings demand it:

- `disable-model-invocation` overridden or `hooks:` field used → read `${CLAUDE_SKILL_DIR}/references/automate-workflows-with-hooks.md`
- `context: fork` or `agent:` used → read `${CLAUDE_SKILL_DIR}/references/create-custom-subagents.md`
- Description mentions CI, scripts, headless, or programmatic invocation → read `${CLAUDE_SKILL_DIR}/references/run-claude-code-programmatically.md`

If none apply, proceed with only the core spec already read.

## Stage 4 — Generate SKILL.md

Build the full SKILL.md in memory from the inferred settings. Frontmatter template:

```yaml
---
name: <inferred name>
description: "<one-sentence what + manual-invocation phrasing>"
argument-hint: [<hint>] # omit if no $ARGUMENTS use
allowed-tools: [<inferred tools>] # omit if chat-only
disable-model-invocation: true # omit only on documented override
---
```

Body sections, in order:
- `## When to act` — empty-input guard
- `## How to <verb>` — numbered steps derived directly from the description
- One worked example (use a 4-backtick outer fence if the body contains triple-backtick fences)
- `## Final checks before responding` — short numbered checklist

Ground every frontmatter field name and capability description in what was read from `extend-claude-with-skills.md` in Stage 2.

## Stage 5 — Preview and confirm

Check whether the target path already exists:

```bash
test -f "$USERPROFILE/.claude/skills/<name>/SKILL.md" && echo "EXISTS" || echo "NEW"
```

If `EXISTS`, prepend this warning to the preview:

> A skill named `<name>` already exists at $USERPROFILE/.claude/skills/<name>/SKILL.md. Overwrite?

Display the full generated SKILL.md (frontmatter + body) inside a 4-backtick outer fence:

````markdown
---
name: <name>
...
---

[body]
````

(The 4-backtick outer fence prevents inner triple-backtick fences in the body from terminating the preview block. The actual file content uses standard triple-backtick fences.)

Below the preview, output a one-line inference summary and a confirm prompt in chat (not via AskUserQuestion):

> **Inferred:** name `<name>` · tools `<tools or "none">` · trigger `<user-only or auto>`
>
> Reply 'yes' to write, or describe changes (e.g. "use Read/Grep instead", "rename to foo-bar", "make it auto-invocable").

Wait for the user reply. If they describe changes, regenerate Stage 4 with the updated settings and show the preview again. Loop until 'yes'.

## Stage 6 — Write the skill

Validate first, mkdir second, Write third. Never reorder.

1. **Validate the name** before any file operation:
   - Matches `^[a-z0-9]+(-[a-z0-9]+)*$`, ≤64 chars
   - Contains no `/`, `..`, or `\`
   If validation fails, output an error and stop — do not run mkdir or Write.

2. **Create the directory** via Bash:
   ```bash
   SKILL_DIR="$USERPROFILE/.claude/skills/<validated-name>"
   mkdir -p "$SKILL_DIR"
   ```
   Use `$USERPROFILE`, not `~` — the Write tool does not expand `~` on Windows (Issue #30553). `$USERPROFILE` is reliably exported in git-bash on Windows.

3. **Write** the generated SKILL.md content to `$SKILL_DIR/SKILL.md`.

## Stage 7 — Confirm

Output in chat:

> Written to $USERPROFILE/.claude/skills/<name>/SKILL.md. Restart Claude Code to load the skill.

## Worked example — end-to-end

User runs `/skill-create a skill that summarizes recent git log output as a bullet list`.

- **Stage 1:** `$ARGUMENTS` non-empty → proceed.
- **Stage 2:** Read `${CLAUDE_SKILL_DIR}/references/extend-claude-with-skills.md`.
- **Stage 3:** Infer:
  - Name: `git-log-summary` (verb "summarize" + object "git log")
  - Trigger: user-only (default — no auto-invoke cue)
  - Tools: chat-only — "summarize" produces chat output; description doesn't say "save to file"
  - argument-hint: `[number-of-commits]` (description implies a count knob)
  - Guard: usage message
  - No conditional refs needed
- **Stage 4:** Generate:

  ````markdown
  ---
  name: git-log-summary
  description: "Summarizes recent git log output as a concise bullet list. Manual invocation only via /git-log-summary [number-of-commits]."
  argument-hint: [number-of-commits]
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

- **Stage 5:** Path NEW. Display preview + inference summary. User replies "yes".
- **Stage 6:** Validate `git-log-summary`, run `mkdir -p "$USERPROFILE/.claude/skills/git-log-summary"`, Write SKILL.md.
- **Stage 7:** "Written to $USERPROFILE/.claude/skills/git-log-summary/SKILL.md. Restart Claude Code to load the skill."

## Final checks before writing

Before executing the write step (Stage 6), confirm:

1. Spec (`extend-claude-with-skills.md`) was read in Stage 2 before any inference.
2. Name was inferred and validated (`^[a-z0-9]+(-[a-z0-9]+)*$`, no `/`, `..`, or `\`).
3. Generated SKILL.md was shown in a 4-backtick fenced preview before writing.
4. Inference summary line listed name, tools, and trigger so the user could spot mismatches.
5. User confirmed with "yes" or equivalent in chat.
6. `mkdir -p` ran before the Write call.
7. `$USERPROFILE` was used — not `~`.
