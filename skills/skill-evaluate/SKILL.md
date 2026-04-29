---
name: skill-evaluate
description: "Audits an existing SKILL.md against the Claude Code skills spec and project conventions, producing a PASS/WARN/FAIL report with line references and suggested fixes. Manual invocation only via /skill-evaluate <skill-name-or-path>."
argument-hint: [skill-name-or-path]
allowed-tools: [Read, Glob, Grep, Bash]
disable-model-invocation: true
---

# Skill Evaluate

The user invoked this with: $ARGUMENTS

## Stage 1 — When to act

If `$ARGUMENTS` is empty or contains only whitespace, output exactly:

> Provide a skill name or path to evaluate, for example:
> `/skill-evaluate skill-create` or `/skill-evaluate ./skills/foo/SKILL.md`

Then stop — do not search, do not guess a target.

Otherwise proceed to Stage 2.

## Stage 2 — Read the spec

Before scoring anything, read the platform spec:

```
${CLAUDE_SKILL_DIR}/references/extend-claude-with-skills.md
```

This is mandatory — every check below refers to a field, limit, or behavior defined there. Do not skip.

## Stage 3 — Resolve the target

`$ARGUMENTS` is either a path or a skill name.

**Path mode** — input contains `/`, `\`, or ends in `.md`:
- Read it directly. If the file does not exist, output `Skill file not found: <path>` and stop.

**Name mode** — input is a bare identifier (matches `^[a-z0-9]+(-[a-z0-9]+)*$`):

Resolve via Bash, in this order, taking the first hit:

```bash
NAME="<input>"
for CANDIDATE in \
  "$USERPROFILE/.claude/skills/$NAME/SKILL.md" \
  ".claude/skills/$NAME/SKILL.md" \
  "skills/$NAME/SKILL.md"
do
  [ -f "$CANDIDATE" ] && echo "FOUND: $CANDIDATE" && break
done
```

If none exist, output the three paths checked and stop.

If the input does not match either form (contains spaces, capitals, or special characters that are not a valid path), output `Invalid skill identifier: <input>` and stop.

## Stage 4 — Read the target

Read the resolved SKILL.md. Also list the skill's directory contents — the report needs to know whether supporting files exist:

```bash
ls -la "$(dirname "<resolved-path>")"
```

## Stage 5 — Conditional reference reads

Load only the references that match what the target actually uses. Do not load all four — the spec already covers the common case.

- If frontmatter declares `hooks:` or the body references `hook` events, read `${CLAUDE_SKILL_DIR}/references/automate-workflows-with-hooks.md`
- If frontmatter declares `context: fork` or `agent:`, read `${CLAUDE_SKILL_DIR}/references/create-custom-subagents.md`
- If the body or description mentions CI, scripts, headless, or non-interactive invocation, read `${CLAUDE_SKILL_DIR}/references/run-claude-code-programmatically.md`

## Stage 6 — Run the checks

Score every check below as **PASS**, **WARN**, or **FAIL**. Cite the SKILL.md line number where the issue lives. If a check does not apply (e.g. no `$ARGUMENTS` use), mark it **N/A**.

### Frontmatter

1. **`name` regex** — matches `^[a-z0-9]+(-[a-z0-9]+)*$`, ≤64 chars. FAIL if it doesn't.
2. **`description` present** — non-empty string. FAIL if missing (allowed by spec but defeats discoverability).
3. **Description budget** — combined length of `description` + `when_to_use` ≤1,536 chars. WARN at >1,200; FAIL at >1,536 (truncated by the platform).
4. **Trigger language front-loaded** — description starts with what the skill does and includes "Use when…" phrasing or trigger phrases. WARN if absent.
5. **`disable-model-invocation` appropriateness** — set to `true` if the skill writes files, runs side-effectful commands, or interviews the user. WARN if a write/Bash skill leaves model invocation enabled.
6. **`allowed-tools` tightness** — every tool listed is actually called in the body; no Bash unless a `bash` block, `!\`...\``, or shell instruction exists; no Write unless the body writes a file. WARN per overreach.
7. **`argument-hint` presence** — present when the body references `$ARGUMENTS`, `$0`, or `$N`. WARN if missing. Square-bracket form per spec examples (`[issue-number]`).
8. **Field validity** — every key in frontmatter is one of the documented fields (`name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `model`, `effort`, `context`, `agent`, `hooks`, `paths`, `shell`). FAIL on unknown keys.

### Body

9. **Length** — body ≤500 lines (spec Tip). WARN at >500; recommend moving reference material into supporting files.
10. **No XML tags** — project convention (CLAUDE.md): "YAML frontmatter + Markdown body — no XML tags". FAIL on any `<tag>...</tag>` not inside a code fence. Triple-backtick code blocks are fine.
11. **Empty-input guard** — if the body uses `$ARGUMENTS`, there is a `## When to act` (or equivalent) section that handles empty/whitespace input and stops. WARN if missing.
12. **Supporting files referenced** — every non-`SKILL.md` file in the skill directory is referenced from the body via a markdown link or path string so Claude knows when to load it. WARN per orphan file.
13. **`${CLAUDE_SKILL_DIR}` for bundled paths** — bundled scripts/refs are addressed via `${CLAUDE_SKILL_DIR}/...`, not relative paths or `~/.claude/skills/<name>/...`. WARN if relative or hardcoded.
14. **Windows-safe writes** — if the body uses Bash to write files under the user home, it uses `$USERPROFILE` rather than `~` (the Write tool does not expand `~` on Windows; Issue #30553). WARN per `~/` write target.

### Hygiene

15. **AskUserQuestion option budget** — every `AskUserQuestion` call uses ≤3 explicit options (the platform appends "Other"; total ≤4). FAIL per call exceeding the limit.

## Stage 7 — Output the report

Use this exact structure. Keep it scannable — one line per check.

```markdown
# Skill Evaluation: <name>

**Path:** <resolved-path>
**Spec:** Claude Code skills (extend-claude-with-skills.md)

## Frontmatter
- ✅ name — PASS
- ✅ description — PASS (1,234 / 1,536 chars)
- ⚠️ argument-hint — WARN (line 4): body uses `$ARGUMENTS` but no hint declared
- ❌ disable-model-invocation — FAIL (line 5): skill writes files but model invocation is enabled

## Body
- ✅ length — PASS (89 / 500 lines)
- ❌ XML tags — FAIL (line 47): `<task>` tag found
- ⚠️ supporting-files — WARN: `references/foo.md` not referenced from body

## Hygiene
- ✅ AskUserQuestion options — PASS

## Summary
- **2 FAIL, 2 WARN, 5 PASS, 1 N/A**

## Suggested fixes
1. Line 5 — add `disable-model-invocation: true` to frontmatter; this skill writes files.
2. Line 47 — replace `<task>...</task>` with a `## Task` heading.
3. Line 4 — add `argument-hint: [target]` to frontmatter.
4. Reference `references/foo.md` from the body so Claude loads it on demand.
```

If the target has zero FAILs and zero WARNs, end with `**Verdict:** Ready to ship.`

## Stage 8 — Do not modify the target

This skill is read-only. Never edit the evaluated SKILL.md or any sibling file. The user takes the report and decides what to change.

## Worked example

User runs `/skill-evaluate skill-create` from this repo.

- **Stage 1:** `$ARGUMENTS` = "skill-create" — proceed.
- **Stage 2:** Read `${CLAUDE_SKILL_DIR}/references/extend-claude-with-skills.md`.
- **Stage 3:** Name mode. Probe order — `$USERPROFILE/.claude/skills/skill-create/SKILL.md` (miss), `.claude/skills/skill-create/SKILL.md` (miss), `skills/skill-create/SKILL.md` (hit).
- **Stage 4:** Read it. List directory — sees `references/` subfolder.
- **Stage 5:** No `hooks:`, no `context: fork`, no CI mentions — load no extra references.
- **Stage 6:** Run all checks. Body uses `$ARGUMENTS`, `argument-hint: [skill-description]` is present → PASS. `disable-model-invocation: true` is set, skill writes files → PASS. Body 235 lines → PASS. References subdirectory used → check 12 verifies each file is mentioned.
- **Stage 7:** Output the report. If clean: `**Verdict:** Ready to ship.`
- **Stage 8:** No file modifications.

## Final checks before responding

1. `extend-claude-with-skills.md` was read before any scoring (Stage 2 ran before Stage 6).
2. The target SKILL.md was located and read (Stage 3 → Stage 4) before any check ran.
3. Every FAIL/WARN cites a line number from the evaluated file.
4. The summary line counts FAIL/WARN/PASS/N/A correctly.
5. No file was written or edited at any point.
