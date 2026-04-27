---
phase: 02-prompt-improvement-skill
plan: 01
subsystem: skills
tags: [improve-prompt, skill-body, prompt-engineering, claude-code]

# Dependency graph
requires:
  - phase: 01-plugin-scaffolding
    provides: "skills/improve-prompt/SKILL.md stub with frozen frontmatter (name, description, argument-hint, disable-model-invocation)"
provides:
  - "Working /improve-prompt skill instruction body implementing four-dimension rewrite algorithm, heuristic idiom injection, three-section output format, and low-info handling"
affects: [02-prompt-improvement-skill, gsd-verify-work]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "4-backtick outer fence for worked examples containing triple-backtick inner fences"
    - "Heuristic injection table (Idiom | Inject when | Example) for conditional behavior"
    - "Imperative body style with brief rationale — avoid narrative voice"
    - "Empty-$ARGUMENTS guard at top of body returning usage message and stopping"

key-files:
  created: []
  modified:
    - skills/improve-prompt/SKILL.md

key-decisions:
  - "Used heuristic table (not prose) for idiom injection rules — deterministic scanning, per RESEARCH.md Pattern 3"
  - "4-backtick outer fences for both worked-example blocks and the format template — prevents inner triple-backtick fence collision (Pitfall 1)"
  - "Empty-args guard outputs blockquote-formatted usage message and stops — does not attempt a rewrite (Pitfall 2)"
  - "Frontmatter (lines 1-6) left byte-for-byte unchanged — verified via git diff (Pitfall 3)"

patterns-established:
  - "Pattern 1: Imperative instruction with reasoning — 'Do X because Y' pattern for every rule in skill bodies"
  - "Pattern 2: Inline worked examples as few-shot guidance using 4-backtick fences"
  - "Pattern 3: Heuristic table for conditional injection — Idiom | Inject when | Example columns"

requirements-completed: [PROMPT-01, PROMPT-02, PROMPT-03, PROMPT-04, PROMPT-05]

# Metrics
duration: 15min
completed: 2026-04-27
---

# Phase 2 Plan 01: Improve Prompt Skill Body Summary

**Four-dimension prompt rewrite skill with heuristic @file/verification/scope injection, bracketed-placeholder low-info handling, and locked three-section chat output — no file writes, no tool calls**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-27T00:00:00Z
- **Completed:** 2026-04-27
- **Tasks:** 1 of 1
- **Files modified:** 1

## Accomplishments

- Replaced placeholder comment block in `skills/improve-prompt/SKILL.md` with a 127-line working instruction body
- Implemented all eight locked decisions (D-01 through D-08) and the empty-args guard from RESEARCH.md Pitfall 2
- Frontmatter (lines 1-6) and intake anchor (line 10) confirmed unchanged via git diff

## Task Commits

Each task was committed atomically:

1. **Task 1: Write the improve-prompt SKILL.md instruction body** — `d41dc9b` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `skills/improve-prompt/SKILL.md` — Body replaced: was 19-line stub with placeholder comment; now 138-line working instruction body covering all five Phase 2 requirements

## Decisions Made

- Used a heuristic Markdown table for idiom injection rules (not prose paragraphs), per RESEARCH.md Pattern 3 — tables produce more deterministic conditional behavior
- Used 4-backtick outer fences for the "How to format output" template block and both worked examples, per RESEARCH.md Pitfall 1 — prevents triple-backtick inner fences from prematurely closing outer fence
- Empty `$ARGUMENTS` outputs a blockquote-formatted usage message and stops without attempting a rewrite — consistent with D-07's "never ask a clarifying question before rewriting" guidance and RESEARCH.md Pitfall 2

## Deviations from Plan

None — plan executed exactly as written. The body was transcribed from the plan's `<action>` block verbatim with no structural changes.

## Issues Encountered

None.

## Automated Verification

All structural grep checks passed:

```
grep -q '^## Original'                       PASS
grep -q '^## Improved'                       PASS
grep -q '^## What Changed'                   PASS
grep -q '^name: improve-prompt$'             PASS
grep -q '^disable-model-invocation: true$'   PASS
grep -q '^argument-hint: <rough-prompt-text>$' PASS
grep -q 'The user invoked this with: $ARGUMENTS' PASS
grep -q '| Idiom |'                          PASS
grep -qE '^\`\`\`\`'                         PASS
grep -q 'To sharpen further, add'            PASS
grep -q 'empty or contains only whitespace'  PASS
! grep -q 'Phase 2 will fill in'             PASS
```

Final line count: 138 lines (minimum 80 required — PASS)

Frontmatter freeze: `git diff` confirms all changes are in lines 12+ with no modifications above the second `---` marker.

## Manual UAT (deferred to phase verification — /gsd-verify-work)

Per VALIDATION.md, PROMPT-02, PROMPT-04, and PROMPT-05 require live invocation to verify LLM reasoning quality. These are not automated. Run the following in Claude Code at `/gsd-verify-work` time:

| Invocation | Expected behavior |
|------------|------------------|
| `/improve-prompt fix the auth bug` | Three sections in order; contains `@file auth/middleware.ts` or similar; contains verification step (`npm test -- auth` or similar); bullets match `- [Label] — [reason]` format |
| `/improve-prompt explain how React hooks work` | Three sections; NO `@file` injection (cue absent — D-05 heuristic test) |
| `/improve-prompt fix it` | Three sections; bracketed placeholders in Improved; `⚠️ To sharpen further, add:` note after What Changed |
| `/improve-prompt` (no argument) | Usage message only; no rewrite attempted |

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The SKILL.md body has `disable-model-invocation: true` and no `allowed-tools` — output is chat-only. T-02-01 (frontmatter tampering) mitigated: verified via git diff. T-02-02 and T-02-03 accepted per threat register.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `skills/improve-prompt/SKILL.md` body is complete and ready for manual UAT via `/gsd-verify-work`
- Phase 3 (skill-create) can begin once Phase 2 verification passes
- No blockers

## Self-Check: PASSED

- FOUND: skills/improve-prompt/SKILL.md
- FOUND: .planning/phases/02-prompt-improvement-skill/02-01-SUMMARY.md
- FOUND commit: d41dc9b

---
*Phase: 02-prompt-improvement-skill*
*Completed: 2026-04-27*
