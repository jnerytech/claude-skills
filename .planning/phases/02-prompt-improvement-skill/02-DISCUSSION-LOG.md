# Phase 2: Prompt Improvement Skill - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-27
**Phase:** 02-prompt-improvement-skill
**Areas discussed:** Output layout, Idiom injection logic, "What changed" depth, Low-info input handling

---

## Output Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Sections + fenced blocks | ## Original / ## Improved / ## What Changed with fenced code blocks for prompts | ✓ |
| Labeled prose + code fence | Bold **Original:** inline, fenced Improved, inline **What Changed:** | |
| Claude decides | SKILL.md adapts layout to prompt length and complexity | |

**User's choice:** Sections + fenced blocks

Follow-up — What Changed format:

| Option | Description | Selected |
|--------|-------------|----------|
| Bullet list per change | One bullet per material improvement made | ✓ |
| Brief paragraph | One or two sentences covering overall thrust | |

**User's choice:** Bullet list per change

Follow-up — coverage:

| Option | Description | Selected |
|--------|-------------|----------|
| Only changes made | Bullets only for dimensions that were actually improved | ✓ |
| All 4 dimensions always | Cover every dimension, noting "unchanged" when nothing improved | |

**User's choice:** Only changes made

**Notes:** User consistently chose the option that maximizes signal/noise — one clean result, no noise from unchanged dimensions.

---

## Idiom Injection Logic

| Option | Description | Selected |
|--------|-------------|----------|
| Heuristic-based | Each idiom fires only when its cue is present in the input | ✓ |
| Always inject all three | Every rewrite gets @file, verification, and scope regardless of type | |
| Claude judges at runtime | SKILL.md says "where appropriate" and defers to model | |

**User's choice:** Heuristic-based

Follow-up — implied filenames:

| Option | Description | Selected |
|--------|-------------|----------|
| Infer plausible path | If file is implied, write @file auth/middleware.ts (guessable) | ✓ |
| Skip @file if not explicit | Only add @file when user already named the file | |

**User's choice:** Infer plausible path

**Notes:** User wants concrete, actionable output even when input is imprecise. Wrong-but-plausible @file is more useful than no @file.

---

## "What Changed" Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Label + brief reason | Change name + one-sentence why it improves the prompt | ✓ |
| Label only | Short phrase, no explanation | |
| Per-dimension summary | One bullet per dimension covering all changes in that dimension | |

**User's choice:** Label + brief reason — format: `- [Change label] — [reason]`

**Notes:** Teaching value matters. User wants the annotation to explain *why* each change is an improvement, not just name it.

---

## Low-Info Input Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Best-effort rewrite + 'sharpen it' note | Always produce something, append ⚠️ note listing what to add | ✓ |
| One clarifying question first | Ask one AskUserQuestion before rewriting | |
| Detect vagueness threshold | Normal rewrite above threshold, question below | |

**User's choice:** Best-effort rewrite + "sharpen it" note

**Notes:** Fast-turnaround is a core design goal (per FEATURES.md anti-feature table: "Full interview before rewriting"). User confirmed: never block on a question, always produce output immediately. Bracketed placeholders (`[describe symptom]`) show structure without asking.

---

## Claude's Discretion

- Exact heuristic thresholds for "code change" vs "explanation" task type
- Ordering of ## What Changed bullets (most impactful first preferred)
- Whether to add scope vs verification when a prompt has one but not the other

## Deferred Ideas

None — discussion stayed within Phase 2 scope.
