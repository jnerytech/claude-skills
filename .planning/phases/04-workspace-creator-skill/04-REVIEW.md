---
phase: 04-workspace-creator-skill
reviewed: 2026-04-29T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - skills/workspace-create/SKILL.md
  - skills/workspace-create/templates/CLAUDE.md.template
findings:
  critical: 3
  warning: 2
  info: 1
  total: 6
status: issues_found
---

# Phase 4: Code Review Report

**Reviewed:** 2026-04-29
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Two files reviewed: the 228-line `workspace-create` skill body and its 37-line CLAUDE.md template. The skill implements a 9-stage interview-driven scaffolder covering all WORK-01 through WORK-06 requirements. Three blockers were found — two are security/logic correctness issues and one is a structural contradiction in the final-checks gate. Two warnings cover a fragile worked-example convention and a markdown-breaking fallback value. One info item flags a user-facing mismatch between the Q1 prompt and validation behavior.

## Critical Issues

### CR-01: `$ARGUMENTS`-supplied name bypasses path-traversal validation entirely

**File:** `skills/workspace-create/SKILL.md:17-40`

**Issue:** Stage 1 (lines 17–19) says: "If `$ARGUMENTS` is non-empty… treat it as the proposed workspace name. Output: 'I'll name this workspace — change it?' Then proceed to Stage 2 using the proposed name." Stage 2 Q1 (line 28) says: "skip if Stage 1 proposed a name and **user confirmed it**." The user confirmation instruction for Stage 1 never contains an explicit "wait for reply" gate (see CR-02 below), but even granting a fix there, the name validation Bash block (lines 32–39) lives inside the Q1 flow that is skipped. There is no second validation pass for `$ARGUMENTS`-supplied names anywhere in the skill.

**Exploit path:** The user invokes `/workspace-create ../../etc/target`. Stage 1 proposes the name. Q1 is skipped. The regex never runs. Stage 4 computes `WORKSPACE_ROOT="$(pwd)/../../etc/target"` and Stage 5 runs `mkdir -p` on a path escaping CWD. This directly contradicts threat mitigation T-04-01, which the plan claims is addressed by the Stage 2 Q1 Bash gate — a gate that is not executed on the `$ARGUMENTS` code path.

**Fix:** Add an unconditional validation step in Stage 1 before proposing the name. If validation fails, output an error and stop — do not proceed to Stage 2 at all:

```markdown
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
```

---

### CR-02: Stage 1 has no reply-wait gate — name "confirmation" is a fire-and-forget

**File:** `skills/workspace-create/SKILL.md:17-22`

**Issue:** Stage 1 outputs "I'll name this workspace `<name>` — change it?" and then immediately says "Then proceed to Stage 2 using the proposed name." There is no instruction to wait for the user's reply. The executing model is instructed to proceed to Stage 2 *immediately after asking the question*, making the confirmation question cosmetic only. By contrast, Stage 3 (line 93) explicitly says "Wait for the user to reply before proceeding to Stage 4." The missing wait gate means:
- The user can never actually change the name via the "change it?" prompt.
- The skip condition in Q1 ("skip if Stage 1 proposed a name and user confirmed it") is unsatisfiable — there is no mechanism for the user to confirm.
- CR-01's exploit path flows through this gap: the name is "confirmed" before the user sees or responds to the question.

**Fix:** Add an explicit wait-for-reply instruction after the output line in Stage 1:

```markdown
If $ARGUMENTS is non-empty and not only whitespace, treat it as the proposed workspace name.
Output: "I'll name this workspace `<$ARGUMENTS>` — change it?"
Wait for the user's reply.
  - If the user says "yes", "ok", or equivalent: proceed to Stage 2 using the proposed name
    (skip Q1 in Stage 2 — name is confirmed).
  - If the user provides a different name: treat that response as the new proposed name,
    validate it per the Q1 Bash block, then proceed to Stage 2.

If $ARGUMENTS is empty or whitespace, proceed directly to Stage 2 with no proposed name.
```

---

### CR-03: Final-checks header references Stage 5 (mkdir) but items 10–12 require Stage 7 outputs

**File:** `skills/workspace-create/SKILL.md:214-228`

**Issue:** The section header (line 216) reads: "Before executing Stage 5 (mkdir), confirm:" — but items 10, 11, and 12 all reference the generated CLAUDE.md content, which is not produced until Stage 7:
- Item 10: "All 6 markers replaced in generated CLAUDE.md; zero `{{` patterns remain."
- Item 11: "`wc -l` on generated CLAUDE.md content is < 195 before Write."
- Item 12: "All Write paths use `$WORKSPACE_ROOT`"

At the time Stage 5 runs, no CLAUDE.md content exists to scan. These checks are structurally unsatisfiable at the stated position. A model following these instructions literally must either skip the checks (rendering them useless) or fail to proceed past Stage 5.

**Fix:** Split into two checklists with accurate positioning:

```markdown
## Pre-mkdir checks (before Stage 5)

1. Workspace name validated with `^[a-z][a-z0-9-]*$` — no `/`, `..`, or `\` in name.
2. All 5 interview questions answered (name, repos, per-repo purpose, goal, stack —
   or blank/skip recorded for Q5).
3. `{{WORKSPACE_NAME}}` and `{{WORKSPACE_GOAL}}` are non-empty (re-asked if needed).
4. `{{STACK}}` has either a user-provided value or the fallback "Not specified".
5. `{{REPO_MAP}}` has either formatted table rows or the fallback "No repos specified".
6. `{{CONVENTIONS}}` has either a derived value or the fallback
   "Follow standard conventions for the stack".
7. Scaffold plan preview shown to user; user replied 'yes' or equivalent.
8. Existing workspace check ran before mkdir; user confirmed if EXISTS.
9. All 9 `mkdir -p` paths use `$WORKSPACE_ROOT` (absolute) — no relative paths,
   no `$USERPROFILE`.

## Pre-Write checks (before Stage 7 Write call)

10. All 6 markers replaced in generated CLAUDE.md; zero `{{` patterns remain.
11. `wc -l` on generated CLAUDE.md content is < 195 before Write.
12. All Write paths use `$WORKSPACE_ROOT` — not `~`, not `$USERPROFILE`,
    not a hardcoded path.
```

---

## Warnings

### WR-01: Worked example uses `\n` literal in REPO_MAP value — table will be malformed if taken literally

**File:** `skills/workspace-create/SKILL.md:204`

**Issue:** The worked example shows:
```
{{REPO_MAP}} → `| api-gateway | Routes all traffic |\n| billing-service | Handles subscriptions |`
```
The `\n` is a literal backslash-n, not a real newline. If a model follows the worked example literally rather than interpreting it semantically, the substitution produces a single-line table body with `\n` text embedded, which breaks the markdown table structure in the output CLAUDE.md. Worked examples in instruction files are often followed more literally than intended.

**Fix:** Show the replacement with actual line-break formatting, or note explicitly that `\n` represents a real newline:

```markdown
{{REPO_MAP}} → two separate table rows (one per line):
  | api-gateway | Routes all traffic |
  | billing-service | Handles subscriptions |
```

---

### WR-02: `{{REPO_MAP}}` fallback "No repos specified" renders as a broken markdown table row

**File:** `skills/workspace-create/templates/CLAUDE.md.template:11` and `skills/workspace-create/SKILL.md:152`

**Issue:** The template (line 11) places `{{REPO_MAP}}` directly under the markdown table header:
```markdown
| Repo | Purpose |
|------|---------|
{{REPO_MAP}}
```
The fallback value is `No repos specified` (a plain prose string). Substituting this into the table-row position produces:
```markdown
| Repo | Purpose |
|------|---------|
No repos specified
```
This is malformed markdown — "No repos specified" is not a table row. Most markdown renderers will break the table or discard the line.

**Fix:** Change the fallback to a valid table row, either in the SKILL.md marker-replacement table or as a consistent convention stated in both places:

```markdown
Fallback if no repos: `| _none_ | No repos specified |`
```

---

## Info

### IN-01: Q1 prompt describes valid names as "lowercase letters, numbers, and hyphens" but regex requires a leading letter

**File:** `skills/workspace-create/SKILL.md:29,34`

**Issue:** The Q1 prompt text (line 29) says: "Use lowercase letters, numbers, and hyphens only (e.g. `my-project`)." This implies names like `123-foo` or `9project` are valid. The actual Bash validation regex (line 34) is `^[a-z][a-z0-9-]*$`, which requires the first character to be a lowercase letter. A user who types `123-api` based on the prompt will receive an "INVALID" response without understanding why, since the prompt said numbers are allowed.

**Fix:** Update the Q1 prompt to state the leading-letter constraint explicitly:

```markdown
> "What should I name this workspace? Use a lowercase letter to start, then lowercase
> letters, numbers, and hyphens (e.g. `my-project`). This becomes the directory name."
```

---

_Reviewed: 2026-04-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
