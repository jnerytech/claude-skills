---
phase: 4
slug: workspace-creator-skill
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-29
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Structural grep (bash) + manual UAT — no automated test runner for skill bodies |
| **Config file** | None — same pattern as Phases 2 and 3 |
| **Quick run command** | `grep -c "WORKSPACE" skills/workspace-create/SKILL.md` |
| **Full suite command** | Manual invocation: `/workspace-create` in a live Claude Code session |
| **Estimated runtime** | ~5 seconds (structural); ~5 min (manual UAT) |

---

## Sampling Rate

- **After every task commit:** Run `grep -c "WORKSPACE" skills/workspace-create/SKILL.md`
- **After every plan wave:** Run full structural grep suite
- **Before `/gsd-verify-work`:** Full structural suite must be green + manual UAT completed
- **Max feedback latency:** 5 seconds (structural greps)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | WORK-01 | — | Skill body present and invocable | structural-grep | `grep -c "workspace" skills/workspace-create/SKILL.md` | ✅ W0 stub | ⬜ pending |
| 4-01-02 | 01 | 1 | WORK-02 | — | Interview questions for name, repos, purpose, goal | structural-grep | `grep -c "repo" skills/workspace-create/SKILL.md` | ✅ W0 stub | ⬜ pending |
| 4-01-03 | 01 | 1 | WORK-03 | T: path traversal | All 7 .workspace/ subdirs in mkdir instruction | structural-grep | `grep -c "\.workspace" skills/workspace-create/SKILL.md` | ✅ W0 stub | ⬜ pending |
| 4-01-04 | 01 | 1 | WORK-04 | — | .claude/ and .vscode/ in mkdir instruction | structural-grep | `grep -c "\.claude\|\.vscode" skills/workspace-create/SKILL.md` | ✅ W0 stub | ⬜ pending |
| 4-01-05 | 01 | 1 | WORK-05 | T: stub leakage | Template file exists; marker replacement present | structural-grep | `test -f skills/workspace-create/templates/CLAUDE.md.template && echo EXISTS` | ❌ W0 gap | ⬜ pending |
| 4-01-06 | 01 | 1 | WORK-05 | T: stub leakage | 200-line guard instruction present | structural-grep | `grep -c "200" skills/workspace-create/SKILL.md` | ✅ W0 stub | ⬜ pending |
| 4-01-07 | 01 | 1 | WORK-06 | — | README.md write instruction for each subdir | structural-grep | `grep -c "README" skills/workspace-create/SKILL.md` | ✅ W0 stub | ⬜ pending |
| 4-UAT   | 01 | — | ALL | ALL | End-to-end workspace creation works | manual-UAT | `/workspace-create` in live session; verify directory tree + CLAUDE.md populated | Manual | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `skills/workspace-create/templates/CLAUDE.md.template` — must be created in Phase 4; currently only `.gitkeep` exists (WORK-05 gap)

*All other structural greps run against the existing stub. No additional test infrastructure required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| End-to-end workspace creation | WORK-01 through WORK-06 | Skill body executes inside a live Claude Code session; structural grep cannot simulate Claude executing the instructions | Invoke `/workspace-create` in a real session, enter workspace name + 2 repos + goals, verify `.workspace/` tree created, CLAUDE.md has no `{{MARKERS}}`, all READMEs present |
| CLAUDE.md line count ≤ 200 | WORK-05 | Must count lines in the generated output file | After creation: `wc -l <workspace-name>/CLAUDE.md` — must be < 200 |
| No `{{MARKERS}}` in output | WORK-05 | Must inspect generated file content | `grep "{{" <workspace-name>/CLAUDE.md` — must return no matches |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
