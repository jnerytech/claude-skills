---
phase: 03-skill-creator-skill
reviewed: 2026-04-27T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - skills/skill-create/SKILL.md
findings:
  critical: 3
  warning: 3
  info: 0
  total: 6
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-04-27
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

`skills/skill-create/SKILL.md` implements a multi-stage interview-to-file-write workflow. The overall structure (stage ordering, option counts, guard logic) is sound. However, three blockers and three warnings were found:

- Two blockers concern correctness of the conditional reference-read logic (two of three trigger conditions are structurally unreachable given the interview's constrained option set) and the overwrite-protection gate (an "Overwrite?" warning is emitted but never enforced as a separate gate before the final "yes" prompt).
- One blocker is a pre-validation ordering gap: an unvalidated name is interpolated into a bash command before the name-validation step runs.
- Three warnings concern: no length cap in the validation regex (violating the platform's 64-char limit), an unresolved bash variable passed to the Write tool, and a restart instruction that contradicts the platform's live-reload behavior.

---

## BLOCKER Issues

### BL-01: Two of three conditional reference-read rules are structurally unreachable

**File:** `skills/skill-create/SKILL.md:86-91`

**Issue:** Stage 5 defines three conditional load rules:

1. Load `automate-workflows-with-hooks.md` if "Topic 1 answer indicates hook-based trigger **or** Topic 2 answer includes Bash hook operations."
2. Load `create-custom-subagents.md` if "Topic 3 answer indicates subagent dispatch or fork-based output."
3. Load `run-claude-code-programmatically.md` if "answers mention CI, scripts, or programmatic invocation."

Cross-referencing with the closed-set interview options at lines 54-80:

- **Topic 1** options: "User-only slash command", "Claude auto-invokes", "Propose based on description". None is a hook-based trigger.
- **Topic 2** options: "Read/Write/Bash (file operations)", "Read/Glob/Grep (search only)", "Chat output only". None mentions hook operations.
- **Topic 3** options: "Chat only", "File write", "Both". None mentions subagent dispatch or fork-based output.
- Rule 3 depends on free-text in `$ARGUMENTS` and may occasionally match — but Rules 1 and 2 are structurally unreachable: no constrained option in Topics 1-3 maps to "hook-based trigger", "Bash hook operations", or "subagent dispatch."

Result: `automate-workflows-with-hooks.md` and `create-custom-subagents.md` are dead reference files that the skill's own logic cannot reach. A user who wants a hook-triggered skill and selects "Other" at Topic 1 will not get the hooks reference read, because the trigger test checks topic answers, not free-text.

**Fix:** Either (a) add hook-related and subagent-related options to the interview (within the ≤3 explicit options limit by consolidating existing options), or (b) change the trigger logic to match on `$ARGUMENTS` and free-text answers rather than on constrained topic choices:

```
- If $ARGUMENTS or any free-text interview answer contains "hook", "on save",
  "on commit", or "workflow event":
  Read ${CLAUDE_SKILL_DIR}/references/automate-workflows-with-hooks.md

- If $ARGUMENTS or any free-text interview answer contains "subagent", "fork",
  "delegate", or "agent":
  Read ${CLAUDE_SKILL_DIR}/references/create-custom-subagents.md
```

---

### BL-02: Unvalidated name interpolated into bash command before validation step runs

**File:** `skills/skill-create/SKILL.md:119-122` (Stage 7) vs. `152-155` (Stage 8)

**Issue:** Stage 7 (Preview, lines 119-122) runs a bash existence check using the skill name before Stage 8 validates it:

```bash
test -f "$USERPROFILE/.claude/skills/<name>/SKILL.md" && echo "EXISTS" || echo "NEW"
```

The name at this point is whatever the user typed in Stage 3's "Enter a different name" branch — it has not been checked against `^[a-z0-9]+(-[a-z0-9]+)*$` and has not been screened for shell metacharacters or path components like `/`, `..`, or `\`. A name containing shell metacharacters (e.g., `foo"; rm -rf "$HOME"; echo "`) is interpolated directly into the `test -f` shell command. Even if `test -f` is read-only, the structural violation is clear: the instructions say "validate first" (line 150) but a bash operation executes one full stage before validation does.

**Fix:** Move name validation from Stage 8 Step 1 to immediately after the name is confirmed in Stage 3. This ensures no bash, mkdir, or Write operation ever receives an unvalidated name:

```
## Infer and confirm the skill name
...
After the user confirms the name, immediately validate:
- Name must match ^[a-z0-9]+(-[a-z0-9]+)*$
- Name must not contain /, .., \, or shell metacharacters
If validation fails, output an error and stop. Do not proceed to Stage 4.
```

Remove the duplicate validation from Stage 8 Step 1 once it is moved earlier.

---

### BL-03: Overwrite warning is not a hard gate — user can bypass it with a single "yes"

**File:** `skills/skill-create/SKILL.md:125-144`

**Issue:** When the existence check returns "EXISTS", Stage 7 instructs Claude to output:

> A skill named `<name>` already exists at `$USERPROFILE/.claude/skills/<name>/SKILL.md`. Overwrite?

The instructions then immediately continue: "Then display the full generated SKILL.md…" and "Then ask in chat: 'Write it? Reply yes to write or describe changes.'"

The only hard gate before writing is the "yes" response to "Write it?" — which appears after both the overwrite warning and the entire skill preview. A user who reads the preview and replies "yes" may be confirming the content looks good, not consciously consenting to overwrite the existing file. The overwrite warning is a passive text statement with no required acknowledgment; it will be visually separated from the eventual write prompt by the full preview block.

Because the Write tool overwrites files unconditionally, there is no safety net at the tool level. An existing skill can be destroyed by a user replying "yes" to the wrong prompt.

**Fix:** When EXISTS is detected, require explicit overwrite consent via AskUserQuestion before displaying the preview, not after:

```
If EXISTS:
  AskUserQuestion: "A skill named `<name>` already exists. What do you want to do?"
  Options (≤3 explicit):
  - "Overwrite the existing skill"
  - "Choose a different name"
  - "Cancel"
  If user selects "Cancel": output "Cancelled." and stop.
  If user selects "Choose a different name": return to Stage 3.
  Only if user selects "Overwrite": proceed to display the preview and write.
```

---

## WARNING Issues

### WR-01: Validation regex has no length cap — violates platform 64-character limit

**File:** `skills/skill-create/SKILL.md:153` and `226`

**Issue:** The validation regex is:

```
^[a-z0-9]+(-[a-z0-9]+)*$
```

The platform spec (`extend-claude-with-skills.md` line 202) states the `name` field accepts "Lowercase letters, numbers, and hyphens only **(max 64 characters)**." The regex imposes no upper bound. A name of 70+ characters passes validation and will be silently wrong at runtime — the platform may truncate it or reject it.

The same regex is cited in the Final Checks checklist at line 226, so both sites need updating.

**Fix:** Keep the existing character-class regex (it correctly rejects consecutive hyphens) and add a separate length check:

```
Validate the name:
1. Must match ^[a-z0-9]+(-[a-z0-9]+)*$
2. Must not contain /, .., or \
3. Must be ≤ 64 characters
```

Update the Final Checks checklist (line 226) to include the length constraint.

---

### WR-02: Write tool receives an unresolved bash variable as its path

**File:** `skills/skill-create/SKILL.md:165`

**Issue:** Stage 8 Step 3 instructs:

> Write the generated SKILL.md content (from Stage 6) to `$SKILL_DIR/SKILL.md`.

`$SKILL_DIR` is a bash shell variable assigned in the preceding `mkdir -p` command block. The Write tool does not execute bash and does not expand shell variables — it requires a literal absolute path. Passing `$SKILL_DIR/SKILL.md` will produce either a literal path starting with `$` (wrong) or require Claude to implicitly remember to expand it, a step the instructions never state.

This is inconsistent with the explicit note at line 162 that the Write tool does not expand `~`. The same logic applies to `$SKILL_DIR`, but no equivalent warning is given.

**Fix:** Replace the bash-variable reference with the fully-expanded path used in the mkdir step:

```
3. **Write the file**:
   Write the generated SKILL.md content (from Stage 6) to:
   `$USERPROFILE/.claude/skills/<validated-name>/SKILL.md`

   Use the expanded path — not $SKILL_DIR, which is a bash variable
   the Write tool cannot resolve.
```

---

### WR-03: Stage 9 restart instruction contradicts platform live-reload behavior

**File:** `skills/skill-create/SKILL.md:171` and `221`

**Issue:** The confirmation message in Stage 9 (lines 171 and 221) instructs:

> Written to `$USERPROFILE/.claude/skills/<name>/SKILL.md`. Restart Claude Code to load the skill.

The platform spec (`extend-claude-with-skills.md` lines 109-110) states:

> "Adding, editing, or removing a skill under `~/.claude/skills/` ... takes effect within the current session without restarting. Creating a top-level skills directory that did not exist when the session started requires restarting Claude Code so the new directory can be watched."

For the common case — a returning user with `~/.claude/skills/` already existing — the restart instruction is incorrect. The skill is live-reloaded automatically. Unconditionally telling the user to restart creates unnecessary friction and may cause them to interrupt an active session.

**Fix:** Condition the restart instruction on whether `~/.claude/skills/` existed before the `mkdir -p`. The `mkdir -p` command in Step 2 can be adapted to detect this:

```bash
# Check before mkdir whether ~/.claude/skills/ already existed
test -d "$USERPROFILE/.claude/skills" && SKILLS_DIR_EXISTED=1 || SKILLS_DIR_EXISTED=0
mkdir -p "$USERPROFILE/.claude/skills/<validated-name>"
```

Then in Stage 9:

```
If SKILLS_DIR_EXISTED=0:
  "Written to ... — restart Claude Code to enable live-watching of the new skills directory."
Else:
  "Written to ... — the skill is available now. Try /<name>."
```

---

_Reviewed: 2026-04-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
