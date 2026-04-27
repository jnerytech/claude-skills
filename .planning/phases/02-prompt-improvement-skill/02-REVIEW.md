---
phase: 02-prompt-improvement-skill
reviewed: 2026-04-27T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - skills/improve-prompt/SKILL.md
findings:
  critical: 0
  warning: 3
  info: 1
  total: 4
status: issues_found
---

# Phase 2: Code Review Report

**Reviewed:** 2026-04-27
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

Reviewed `skills/improve-prompt/SKILL.md`, the single deliverable for Phase 2. The file is a SKILL.md instruction body with YAML frontmatter and a Markdown prose body — no executable code. Review applies instruction-body quality checks: correctness of conditional logic, formatting edge-case handling, and internal consistency.

No security vulnerabilities apply (no tools, no file writes, no credentials, no external calls — confirmed by `disable-model-invocation: true` and absent `allowed-tools`). No BLOCKER-level defects found.

Three warnings and one info item are raised.

---

## Warnings

### WR-01: User input containing triple-backticks breaks the Original fence block

**File:** `skills/improve-prompt/SKILL.md:62-76`
**Issue:** The "How to format output" template wraps the verbatim `$ARGUMENTS` content inside a triple-backtick fenced code block:

```
## Original
```
[the user's rough prompt — verbatim, unchanged]
```
```

If the user's rough prompt itself contains triple-backticks (for example, if they paste a code snippet as their prompt), the inner backticks will prematurely close the outer fence. The rendered output will be malformed: the remainder of the user's prompt appears as prose outside the block, and subsequent sections (`## Improved`, `## What Changed`) may render incorrectly.

The skill has no handling rule for this case. The "verbatim, unchanged" instruction actively prevents Claude from escaping the backticks.

**Fix:** Add a fence-escalation rule in the "How to format output" section:

> If the user's prompt contains triple-backtick sequences, use a 4-backtick (````) outer fence for the Original block so the inner triple-backticks do not terminate it prematurely. All other blocks may remain triple-backtick.

Alternatively, instruct Claude to replace lone ` ``` ` occurrences inside the Original block with `~~~` (tilde fences) — CommonMark allows mixed fence characters for nesting. The fix should mirror the same 4-backtick pattern already applied for worked examples in lines 62-76.

---

### WR-02: "Output exactly:" empty-arguments message uses blockquote markers — ambiguous literal reproduction

**File:** `skills/improve-prompt/SKILL.md:14-19`
**Issue:** The empty-arguments guard reads:

```
If `$ARGUMENTS` is empty or contains only whitespace, output exactly:

> Provide the rough prompt you want improved as an argument, for example:
> `/improve-prompt fix the auth bug`
```

"Output exactly:" sets a strict expectation. However, the message is encoded with `>` Markdown blockquote markers. It is ambiguous whether Claude should reproduce the `>` characters literally in its reply, or treat them as a Markdown formatting hint that renders as a blockquote (without the `>` being visible to the user).

In practice Claude will interpret `>` as blockquote syntax and render the message without the `>` characters, but the phrase "output exactly" suggests the opposite. This inconsistency may cause Claude to reproduce the `>` as literal text on some invocations.

**Fix:** Replace the blockquote encoding with a fenced code block for the prescribed output, making the boundary between "instruction to Claude" and "text to output" unambiguous:

```markdown
If `$ARGUMENTS` is empty or contains only whitespace, output exactly:

```
Provide the rough prompt you want improved as an argument, for example:
/improve-prompt fix the auth bug
```

Then stop — do not attempt a rewrite, do not ask a clarifying question.
```

---

### WR-03: Inconsistent placeholder label between "How to format output" and "Final checks"

**File:** `skills/improve-prompt/SKILL.md:74-78` and `134-135`
**Issue:** The "How to format output" section (line 74-78) specifies the What Changed bullet pattern as:

```
- [Change label] — [one-sentence reason why it improves the prompt]
```

The "Final checks before responding" section (line 134-135) uses a different label for the same placeholder:

```
4. Every bullet under `## What Changed` matches `- [Label] — [reason]`.
```

`[Change label]` vs `[Label]`, and `[one-sentence reason why it improves the prompt]` vs `[reason]`. These are inconsistent names for the same structural slots. While the intent is clear to a human reader, Claude reads the body at inference time as instructions. An inconsistency between the definition site and the check site could cause Claude to treat these as distinct patterns and misapply the validation.

**Fix:** Normalize the Final checks item to match the canonical definition:

```markdown
4. Every bullet under `## What Changed` matches `- [Change label] — [one-sentence reason why it improves the prompt]`.
```

---

## Info

### IN-01: Description field routing cues are unreachable — `disable-model-invocation: true` prevents auto-invocation

**File:** `skills/improve-prompt/SKILL.md:3`
**Issue:** The frontmatter `description` field includes routing cues:

```
"...Use when the user invokes /improve-prompt or asks to 'improve this prompt', 'rewrite this prompt', or 'make this prompt clearer'. Do NOT use for general writing improvements..."
```

The field `disable-model-invocation: true` is set on line 5. This flag prevents Claude from auto-invoking the skill based on these cues. The "Use when..." and "Do NOT use..." guidance in the description will never be evaluated at runtime — the skill can only be triggered by an explicit `/improve-prompt` invocation.

The cues are not harmful, but they are dead wording that adds noise to the description field. The description is also surfaced in skill listings and discovery UX, so the routing language may confuse users into thinking the skill auto-activates.

**Fix:** Trim the description to what is actually useful for the listing context:

```yaml
description: "Rewrites a rough prompt for clarity, specificity, context richness, and structure."
```

The `argument-hint` field already communicates how to invoke it, and `disable-model-invocation: true` makes the routing cues moot.

---

_Reviewed: 2026-04-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
