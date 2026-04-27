---
phase: 3
slug: skill-creator-skill
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-27
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Structural grep (bash) + manual UAT — no automated test runner for skill bodies |
| **Config file** | None — following Phase 2 pattern |
| **Quick run command** | `grep -c "When to act" skills/skill-create/SKILL.md` |
| **Full suite command** | Manual invocation: `/skill-create a skill that summarizes git logs` |
| **Estimated runtime** | ~5 seconds (grep); ~2 min (manual UAT) |

---

## Sampling Rate

- **After every task commit:** Run the structural grep from the Per-Task map below for that task's requirement
- **After every plan wave:** Run all structural grep checks (full table below)
- **Before `/gsd-verify-work`:** All structural greps green + manual UAT approved
- **Max feedback latency:** ~5 seconds (grep checks)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | SKILL-01 | — | Empty-args guard halts before any tool calls | structural-grep | `grep -c "empty or contains only whitespace" skills/skill-create/SKILL.md` | ✅ | ⬜ pending |
| 03-01-02 | 01 | 1 | SKILL-01 | — | $ARGUMENTS ingestion present | structural-grep | `grep -c "ARGUMENTS" skills/skill-create/SKILL.md` | ✅ | ⬜ pending |
| 03-01-03 | 01 | 1 | SKILL-02 | — | Reference doc read instruction present | structural-grep | `grep -c "CLAUDE_SKILL_DIR" skills/skill-create/SKILL.md` | ✅ | ⬜ pending |
| 03-01-04 | 01 | 1 | SKILL-03 | — | AskUserQuestion usage instruction present | structural-grep | `grep -c "AskUserQuestion" skills/skill-create/SKILL.md` | ✅ | ⬜ pending |
| 03-01-05 | 01 | 1 | SKILL-03 | — | All four interview topics present | structural-grep | `grep -cE "trigger\|disable-model-invocation\|allowed-tools\|output dest\|guard" skills/skill-create/SKILL.md` | ✅ | ⬜ pending |
| 03-01-06 | 01 | 1 | SKILL-04 | — | Preview and write-gate instruction present | structural-grep | `grep -c "Write it" skills/skill-create/SKILL.md` | ✅ | ⬜ pending |
| 03-01-07 | 01 | 1 | SKILL-05 | T-path-traversal | Skill name validated before write (reject /, .., \) | structural-grep | `grep -c "USERPROFILE" skills/skill-create/SKILL.md` | ✅ | ⬜ pending |
| 03-01-08 | 01 | 1 | SKILL-05 | T-write-without-mkdir | mkdir -p before Write | structural-grep | `grep -c "mkdir" skills/skill-create/SKILL.md` | ✅ | ⬜ pending |
| 03-E2E | 01 | 1 | ALL | ALL | End-to-end skill creation completes successfully | manual-UAT | `/skill-create a skill that summarizes git log output` | Manual | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

All structural grep commands run against `skills/skill-create/SKILL.md` — the stub already exists. Tests pass automatically once the body is written. No new test files needed; no framework install required.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Empty-args guard outputs correct usage message | SKILL-01 | Requires live Claude Code session to invoke `/skill-create` with no args | Run `/skill-create` (no args) — output must say "Provide a description of the skill you want to create" and stop |
| Interview flow asks ≤6 questions total including name | SKILL-03 | Requires live Claude Code session to count AskUserQuestion calls | Run `/skill-create a skill that summarizes git log output` — count total questions including name confirmation |
| 4-backtick preview renders without truncation | SKILL-04 | Requires visual inspection in Claude Code chat | After interview, verify SKILL.md preview is complete — not truncated at first triple-backtick |
| Skill written to correct global path and loads in new session | SKILL-05 | Requires filesystem check and new session verification | After confirm: check `$USERPROFILE/.claude/skills/<name>/SKILL.md` exists; open new Claude Code session and verify `/name` is available |

---

## Validation Sign-Off

- [x] All tasks have structural grep verify command
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0: no new test files needed (stub already exists)
- [x] No watch-mode flags
- [x] Feedback latency < 10s (grep checks)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-27
