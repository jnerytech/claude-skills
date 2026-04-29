---
name: skill-improve
description: "Audits an existing Claude Code skill against the best-practice rules in the bundled reference docs (extend-claude-with-skills, automate-workflows-with-hooks, create-custom-subagents, run-claude-code-programmatically), proposes a corrected SKILL.md with frontmatter, body, tools, trigger, and supporting-file fixes, previews the changes, and rewrites the file after the user confirms. Manual invocation only via /skill-improve <path-or-skill-name>."
argument-hint: [path-or-skill-name]
allowed-tools: [Read, Write, Bash, Glob]
disable-model-invocation: true
model: opus
---

# Skill Improve

The user invoked this with: $ARGUMENTS

## Stage 1 — When to act

If `$ARGUMENTS` is empty or contains only whitespace, output exactly:

> Provide a path to a SKILL.md, a skill directory, or a skill name, for example:
> `/skill-improve ~/.claude/skills/my-skill/SKILL.md`
> `/skill-improve ./skills/api-style`
> `/skill-improve api-style`

Then stop — do not infer, do not ask a clarifying question.

Otherwise proceed to Stage 2.

## Stage 2 — Read every reference

This skill's job is to apply *all* of the bundled references. Read them in this order before any audit decision:

1. `${CLAUDE_SKILL_DIR}/references/extend-claude-with-skills.md` — base spec for frontmatter, body, tools, name, description, invocation control, supporting files. Authoritative.
2. `${CLAUDE_SKILL_DIR}/references/automate-workflows-with-hooks.md` — hook-related fields (`hooks:`), event triggers, ordering rules.
3. `${CLAUDE_SKILL_DIR}/references/create-custom-subagents.md` — `agent:` field, `context: fork`, isolated execution rules.
4. `${CLAUDE_SKILL_DIR}/references/run-claude-code-programmatically.md` — headless / CI considerations, non-interactive invocation.

All four are mandatory. Do not short-circuit. The audit checklist in Stage 5 cites rules from each — you cannot apply a rule you have not read.

## Stage 3 — Resolve the target skill

`$ARGUMENTS` is one token. Resolve in this order:

| Form | Action |
|---|---|
| Path ends in `SKILL.md` | `Read` directly. |
| Path is a directory containing `SKILL.md` | `Read` `<dir>/SKILL.md`. |
| Bare name (no slash, no `.md`) | Try in order: `./skills/<name>/SKILL.md`, `./.claude/skills/<name>/SKILL.md`, `$USERPROFILE/.claude/skills/<name>/SKILL.md`. First hit wins. If none match, error and stop. |
| Anything else | Error: "Could not resolve `<arg>` to a SKILL.md." Stop. |

Capture the resolved absolute path and the full file contents. Also `Glob` the skill directory for siblings (`*.md`, `references/**`, templates) — Stage 5 may flag the body as too long and recommend splitting into supporting files.

## Stage 4 — Parse current state

Split the file into:
- **Frontmatter**: YAML between the opening and closing `---` lines. Parse keys: `name`, `description`, `argument-hint`, `allowed-tools`, `disable-model-invocation`, `model`, `agent`, `context`, `hooks`. Record any unknown keys verbatim.
- **Body**: everything after the closing `---`. Note section headings (`## …`), code-fence count, presence of an empty-input guard, presence of a worked example, presence of a final-checks section.

Do not modify anything yet. This stage is read-only; Stage 5 produces the diagnosis.

## Stage 5 — Audit against the checklist

Run every check below. For each, mark **PASS**, **FIX**, or **N/A**, and record the source rule (filename + section). The checklist is grouped by reference doc so the citation map is obvious.

### From `extend-claude-with-skills.md`

1. `name` matches `^[a-z0-9]+(-[a-z0-9]+)*$`, ≤64 chars.
2. `description` is third person, present tense, names *what* the skill does AND *when* to use it. ≤1024 chars.
3. If `disable-model-invocation: true`, description ends with `Manual invocation only via /<name> [args].` (omit `[args]` when no argument).
4. `argument-hint` uses square brackets (`[thing]`), omitted when the body never references `$ARGUMENTS`.
5. `allowed-tools` is the minimal set. Flag tools that the body does not use. Flag missing tools that the body clearly needs.
6. `disable-model-invocation: true` is present unless the skill is documented reference content with no side effects.
7. Body opens with an empty-input guard when `argument-hint` is set.
8. Body uses staged structure (`## Stage N — …`) or numbered steps for procedural skills.
9. Body contains at least one worked example for non-trivial skills.
10. Body ends with a `## Final checks` section listing pre-write validations for skills that produce files.
11. No XML tags in frontmatter or body (Markdown only).
12. Long reference material (>~150 lines) is split into `references/*.md` and linked from the body, not inlined.
13. If the skill writes to disk, paths use `$USERPROFILE`, never `~` (Windows expansion bug, Issue #30553).

### From `automate-workflows-with-hooks.md`

14. If `hooks:` is set, each hook lists a valid `event` and `command` (or `script`) per the doc's schema.
15. Hooks declared but never used in the body → flag as dead config.
16. Body describes hook side effects when `hooks:` is set, so the user can audit them.

### From `create-custom-subagents.md`

17. If `agent:` or `context: fork` is set, the body explains why isolation is required.
18. `context: fork` skills do not assume parent-context state (no references to prior conversation).
19. Sub-agent skills cite which tools the spawned agent needs versus which the parent retains.

### From `run-claude-code-programmatically.md`

20. If the skill is intended for CI/headless use, it tolerates missing `$ARGUMENTS` interactively (skipping `AskUserQuestion`) or documents that limitation.
21. Skills invoked via the SDK or `--print` mode avoid `AskUserQuestion`-style prompts in the critical path; if used, they have a documented fallback.

For each FIX, write a one-line diagnosis: what is wrong, which rule it violates, what the fix is.

## Stage 5.5 — Capability suggestions (be creative)

The audit catches violations. This stage proposes *additions* — capabilities the skill does not have but would clearly benefit from. Always run it. Each suggestion must cite which reference doc supports the pattern.

Read the body's actual purpose, not just its current shape. A skill that "formats on demand" is one keystroke away from "formats automatically on save." A skill that "summarizes diffs" is one config away from running headless in CI. Surface the upgrade path; let the user pick.

Examine each lens below and produce 0–3 suggestions per lens. Skip a lens when it does not apply — do not invent reasons.

### Lens 1 — Hooks (`automate-workflows-with-hooks.md`)

Trigger this lens when the skill describes a verb that maps to a tool event. Common patterns:

| Body says… | Suggest |
|---|---|
| "format the file", "lint", "fix style" | `PostToolUse` hook on `Edit`/`Write` to run the skill automatically after file changes |
| "validate before commit", "check the message" | `UserPromptSubmit` or `PreToolUse` hook on `Bash` matching `git commit` |
| "summarize what just happened" | `Stop` hook to run after the agent finishes a turn |
| "warn before destructive action" | `PreToolUse` hook on `Bash` with destructive-command matchers |
| Skill currently requires manual `/invoke` for something the user does on a fixed cadence | propose hook + matcher to remove the manual step |

Output suggestions as: `Hook: <event> <matcher> → <effect>. Why: <one sentence>. Source: automate-workflows-with-hooks.md.`

### Lens 2 — Sub-agents (`create-custom-subagents.md`)

Trigger when the skill:
- Runs many parallel investigations (e.g., grepping multiple paths, fetching multiple URLs) → propose `agent:` or `context: fork` so the noisy work does not bloat the parent context.
- Needs to operate on untrusted/foreign data (migrating a stranger's prompt, parsing a downloaded file) → propose isolation so prompt-injection attempts cannot reach the parent agent.
- Runs a long checklist where intermediate tool output is uninteresting (audit, sweep, scan) → propose returning a compact summary from a forked context.

Output as: `Sub-agent: <name> with <tools> in <forked|isolated> context. Why: <one sentence>. Source: create-custom-subagents.md.`

### Lens 3 — Headless / programmatic (`run-claude-code-programmatically.md`)

Trigger when the skill could plausibly run unattended:
- Output is deterministic given inputs (audit reports, formatters, validators).
- The skill currently uses `AskUserQuestion` only for confirmation, not for decisions — propose a `--yes` or non-interactive flag pattern.
- Skill maps cleanly to a CI step (lint-on-PR, summary-on-merge, security-scan-on-push).

Output as: `Headless: invoke via \`claude --print "/skill-name <args>"\` in <context>. Why: <one sentence>. Source: run-claude-code-programmatically.md.`

### Lens 4 — Dynamic context injection (`extend-claude-with-skills.md`)

Trigger when the body asks the user to paste live state (git status, current branch, file contents). Propose `` !`command` `` injection so the skill grabs the state itself at invocation time.

Output as: `Dynamic context: replace "paste git status" with \`!\`git status --porcelain\`\` at the top of the body. Why: <one sentence>. Source: extend-claude-with-skills.md.`

### Lens 5 — Supporting files (`extend-claude-with-skills.md`)

Trigger when:
- Body inlines a long template, schema, or example block (>30 lines) — propose extracting to `references/<topic>.md` and referencing by path.
- Body re-explains a doc that already exists in `references/` — propose linking instead of duplicating.
- Skill produces output that could be templated (commit messages, PR descriptions) — propose adding a `templates/<name>.md` file the body fills in.

Output as: `Supporting file: <relative path> containing <what>. Why: <one sentence>. Source: extend-claude-with-skills.md.`

### Lens 6 — Argument design (`extend-claude-with-skills.md`)

Trigger when:
- Body branches heavily on flag-like inputs but `argument-hint` does not document them — propose a richer hint, e.g. `[--target=path] [--mode=audit|fix]`.
- Skill silently ignores extra arguments — propose handling them or warning.
- Skill takes a single arg today but would compose better with a piped list (one per line) — propose multi-input support.

Output as: `Argument: <new shape>. Why: <one sentence>. Source: extend-claude-with-skills.md.`

### Suggestion budget

Cap total suggestions at **5** for the whole skill. Pick the highest-leverage ones — do not pad. Better to surface three good ideas than ten weak ones. If nothing rises above the bar, output `No upgrade suggestions — the skill is already fit for purpose.` and move on.

Each suggestion is opt-in. Stage 7 lets the user accept, reject, or modify each one individually before any change is applied.

## Stage 6 — Generate the improved SKILL.md

Apply every FIX from Stage 5 unconditionally. **Mark every Stage 5.5 suggestion as opt-in** — do not bake them into the generated file yet. Stage 7 collects the user's choices; only then does Stage 6 re-run with accepted suggestions applied.

Specifically for the FIXes:

- Rewrite the description only when it fails check 2 or 3.
- Trim or extend `allowed-tools` based on actual body usage (check 5).
- Add the empty-input guard if missing (check 7).
- Restructure into stages only when the body is procedurally tangled and reads as a wall of prose.
- Add a `## Final checks` section if the skill writes files and lacks one.
- If body length exceeds ~150 lines AND check 12 fires, propose moving specific sections to `references/<topic>.md`. List the proposed file names and contents in the preview; do not split silently.

Keep all original frontmatter keys the user set, even unknown ones, unless a rule explicitly requires removal.

When a Stage 5.5 suggestion is accepted in Stage 7, on the next pass through this stage:

- **Hook suggestion accepted** → add a `hooks:` block to frontmatter per `automate-workflows-with-hooks.md`. Document the hook's effect under a `## Hook behavior` body section.
- **Sub-agent suggestion accepted** → add the appropriate `agent:` or `context: fork` field per `create-custom-subagents.md`. Document tool boundaries between parent and child in the body.
- **Headless suggestion accepted** → add a `## Headless usage` section showing the `claude --print` invocation; if needed, gate `AskUserQuestion` calls on an interactive check.
- **Dynamic context accepted** → insert the `` !`command` `` line near the top of the body, replacing the manual paste instruction.
- **Supporting file accepted** → write the new file to `<skill-dir>/<relative-path>` in Stage 8 and replace the inlined block in the body with a one-line reference.
- **Argument design accepted** → update `argument-hint` and the empty-input guard text to match the new shape.

## Stage 7 — Preview, summary, confirm

Display the corrected SKILL.md inside a 4-backtick fenced block:

````markdown
---
name: …
---

[improved body]
````

Below the preview, output the audit summary as a checklist:

> **Audited against:** extend-claude-with-skills · automate-workflows-with-hooks · create-custom-subagents · run-claude-code-programmatically
>
> **Findings (applied):**
> - ✓ <PASSed check #N>: <short note>
> - ✗ <FIXed check #N>: <one-line diagnosis> → <one-line fix>
> - … (one line per check that was not N/A)
>
> **Upgrade suggestions (opt-in — not yet applied):**
> 1. <lens>: <one-line proposal>. *Why:* <reason>. *Source:* <ref filename>.
> 2. …
> (Or: `No upgrade suggestions — the skill is already fit for purpose.`)
>
> **Files changed:** `<path>` · **New supporting files:** `<list or "none">` · **Backup will be created at:** `<path>.bak`
>
> Reply with one of:
> - `yes` — accept the FIXes only, skip all suggestions.
> - `yes + 1,3` — accept FIXes and suggestions 1 and 3.
> - `yes + all` — accept FIXes and every suggestion.
> - Free-form changes (e.g. "skip the description rewrite", "modify suggestion 2 to use PreToolUse instead", "rename to foo-bar").
>
> If suggestions are accepted, regenerate the preview with them applied and confirm again before writing.

Wait for the user reply. If they describe changes, regenerate Stage 6 with their constraints and show the preview again. Loop until 'yes'.

## Stage 8 — Backup and write

Validate first, backup second, write third. Never reorder.

1. **Validate** any renamed `name` against `^[a-z0-9]+(-[a-z0-9]+)*$`, ≤64 chars, no `/`, `..`, or `\`. If the audit changed the name, also confirm with the user that the parent directory should be renamed (it should — slug must match path). If the user declined the rename in Stage 7, keep the original name.

2. **Backup** the existing SKILL.md via Bash:
   ```bash
   cp "<resolved-path>" "<resolved-path>.bak"
   ```
   This is mandatory. Skill rewrites are destructive; the `.bak` is the user's undo.

3. **Write** the improved SKILL.md to the original resolved path.

4. **Write supporting files** (if Stage 6 proposed splits) into `<skill-dir>/references/`. `mkdir -p` first. Use `$USERPROFILE`, not `~`, on Windows-rooted paths.

## Stage 9 — Report

Output in chat:

> Improved `<resolved path>` (backup at `<path>.bak`).<br>
> `<count>` issues fixed across `<n>` reference docs.<br>
> `<count>` supporting files written to `<skill-dir>/references/` (or "no supporting files added").<br>
> Restart Claude Code to reload the skill.

## Worked example

User runs `/skill-improve ./skills/api-style`.

- **Stage 1:** non-empty → proceed.
- **Stage 2:** read all four references.
- **Stage 3:** resolve `./skills/api-style/SKILL.md`. Glob finds no siblings.
- **Stage 4:** parse. Frontmatter has `name: api-style`, no `disable-model-invocation`, `description: "I help enforce API style"`. Body is 30 lines of prose, no stages, no example, no final checks, no empty-input guard. `argument-hint: [endpoint]` set.
- **Stage 5:** findings (abbreviated):
  - ✗ Check 2: description is first person, missing *when* — violates spec ("Description as auto-trigger" section).
  - ✗ Check 3: `disable-model-invocation` absent so default auto-invoke applies, but description has no manual phrasing either way → ambiguous. Decide based on body content.
  - ✗ Check 7: `argument-hint: [endpoint]` set but no empty-input guard at body start.
  - ✓ Check 1, 4, 11.
  - N/A: 14–21 (no hooks, no agent, not headless).
- **Stage 5.5:** suggestions:
  1. **Hook**: `PostToolUse` on `Edit`/`Write` matching `src/api/**` → run the skill automatically after API file edits. *Why:* style review currently requires a manual `/api-style` per file. *Source:* automate-workflows-with-hooks.md.
  2. **Headless**: invoke via `claude --print "/api-style $FILE"` in CI on PRs touching `src/api/`. *Why:* the audit is deterministic and would catch violations before review. *Source:* run-claude-code-programmatically.md.
  3. **Sub-agent**: spawn forked context for multi-endpoint sweeps. *Why:* current body greps every route in the parent context, bloating it. *Source:* create-custom-subagents.md.
- **Stage 6:** generate with FIXes only (description rewrite, `disable-model-invocation: true`, empty-input guard).
- **Stage 7:** preview + findings + 3 suggestions. User replies `yes + 1,2`.
- **Stage 6 (re-run):** add `hooks:` block + `## Hook behavior` section + `## Headless usage` example.
- **Stage 7:** new preview. User replies `yes`.
- **Stage 8:** backup, write.
- **Stage 9:** report: "3 issues fixed · 2 suggestions applied (hook, headless) · 1 deferred."

## Final checks before writing

Before executing Stage 8, confirm:

1. All four references in `${CLAUDE_SKILL_DIR}/references/` were read in Stage 2.
2. Resolved path is absolute and points to an existing `SKILL.md`.
3. Every audit check was marked PASS / FIX / N/A with a rule citation.
4. Stage 5.5 suggestions (or `No upgrade suggestions`) were produced and shown to the user.
5. Each accepted suggestion is reflected in the regenerated preview before writing.
6. Improved SKILL.md was shown in a 4-backtick fenced preview after the final round of changes.
7. Audit summary listed each non-N/A check on its own line and included the suggestion list.
8. User confirmed with "yes" or equivalent on the final preview.
9. `.bak` copy was created before the Write call.
10. `$USERPROFILE` was used for any Windows-rooted write — not `~`.
11. If the `name` was renamed, the parent directory rename was confirmed by the user.
