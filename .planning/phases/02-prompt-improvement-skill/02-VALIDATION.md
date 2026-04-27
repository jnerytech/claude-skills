---
phase: 2
slug: prompt-improvement-skill
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-27
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual UAT (no automated framework — LLM reasoning quality not machine-checkable) |
| **Config file** | none |
| **Quick run command** | `grep "## Original\|## Improved\|## What Changed" skills/improve-prompt/SKILL.md` |
| **Full suite command** | `/improve-prompt fix the auth bug` in Claude Code — verify output matches canonical example |
| **Estimated runtime** | ~2 min (manual) |

---

## Sampling Rate

- **After every task commit:** Run `grep "## Original\|## Improved\|## What Changed" skills/improve-prompt/SKILL.md`
- **After every plan wave:** Run the three UAT test cases from CONTEXT.md `<specifics>` manually
- **Before `/gsd-verify-work`:** Full manual UAT must pass — human review against canonical example
- **Max feedback latency:** ~2 minutes (manual invocation + review)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | PROMPT-01 | — | N/A | smoke | `cat skills/improve-prompt/SKILL.md \| grep -c "## Original"` (must be >= 1) | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | PROMPT-03 | — | N/A | structural | `grep "## Original\|## Improved\|## What Changed" skills/improve-prompt/SKILL.md` | ✅ | ⬜ pending |
| 02-01-03 | 01 | 1 | PROMPT-02 | — | N/A | manual-only | Invoke `/improve-prompt fix the auth bug`, inspect all 4 dimensions improved | ❌ Wave 0 | ⬜ pending |
| 02-01-04 | 01 | 1 | PROMPT-04 | — | N/A | manual-only | Invoke skill, verify bullet format: `- [Label] — [reason]` | ❌ Wave 0 | ⬜ pending |
| 02-01-05 | 01 | 1 | PROMPT-05 | — | N/A | manual-only | Invoke `/improve-prompt fix the auth bug`, verify `@file` appears in output | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `skills/improve-prompt/SKILL.md` body — deliverable itself (stub → working instruction body)

*Wave 0 is the single plan for this phase. No separate test scaffolding needed — the deliverable is the SKILL.md body.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Four dimensions applied to rewrite | PROMPT-02 | LLM reasoning quality — no grep can evaluate whether output is actually improved | Invoke `/improve-prompt fix the auth bug`, confirm clarity/specificity, context richness, structure, and scope/verification are all improved vs original |
| What Changed bullets have label + reason format | PROMPT-04 | Format correctness requires reading each bullet, not just checking presence | Invoke skill, verify each bullet matches `- [Change label] — [one-sentence reason]` pattern from D-03 |
| Claude Code idioms injected heuristically only | PROMPT-05 | Requires checking that idioms appear when cues are present AND absent when cues are not | Test 1: `/improve-prompt fix the auth bug` → `@file` should appear. Test 2: `/improve-prompt explain how React hooks work` → no `@file` needed |
| Low-info guard outputs sharpen note | PROMPT-01 (D-07/D-08) | Conditional behavior — fire on low-info only | Invoke `/improve-prompt fix it` — should show bracketed placeholders + `⚠️ To sharpen further, add:` note |
| Empty `$ARGUMENTS` guard triggers usage message | PROMPT-01 (Pitfall 2) | Zero-input edge case | Invoke `/improve-prompt` with no argument — should output usage message, not attempt rewrite |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5 min
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
