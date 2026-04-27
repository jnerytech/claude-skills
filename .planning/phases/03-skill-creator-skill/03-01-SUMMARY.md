---
plan: 03-01
phase: 03-skill-creator-skill
status: complete
completed: 2026-04-27
---

# Summary: Write skill-create SKILL.md instruction body

## What was built

Replaced the placeholder comment block in `skills/skill-create/SKILL.md` (lines 11–20) with a complete 9-stage Markdown instruction body. The frontmatter (lines 1–7) was left unchanged.

## Stages delivered

1. **When to act** — empty-args guard outputs usage message and stops
2. **Read reference documentation** — mandatory read of `extend-claude-with-skills.md` before any AskUserQuestion
3. **Infer and confirm the skill name** — kebab-case name proposed, confirmed with 2-option AskUserQuestion
4. **Adaptive interview** — four required topics, each with ≤3 explicit AskUserQuestion options
5. **Conditional reference reads** — hooks/subagents/programmatic refs loaded only when interview reveals need
6. **Generate the SKILL.md content** — in-memory generation with frontmatter template
7. **Preview the generated skill** — overwrite warning + 4-backtick fenced preview + chat-level "Write it?" gate
8. **Write the skill** — validate → mkdir -p ($USERPROFILE) → Write, strict sequence enforced
9. **Confirm** — "Restart Claude Code" message after successful write

Also includes: worked example (end-to-end git-log-summary flow) and "Final checks before writing" checklist.

## Self-Check: PASSED

All structural acceptance criteria met:

| Check | Result |
|-------|--------|
| `grep -c "empty or contains only whitespace"` | 2 (≥1) |
| `grep -c "ARGUMENTS"` | 9 (≥1) |
| `grep -c "CLAUDE_SKILL_DIR"` | 5 (≥3) |
| `grep -c "AskUserQuestion"` | 7 (≥5) |
| `grep -c "disable-model-invocation"` | 5 (≥2) |
| `grep -c "allowed-tools"` | 5 (≥2) |
| `grep -c "Write it"` | 2 (≥1) |
| `grep -c "USERPROFILE"` | 9 (≥3) |
| `grep -c "mkdir"` | 7 (≥2) |
| `grep -c "Final checks"` | 2 (≥1) |
| `grep -c "Overwrite"` | 1 (≥1) |
| `grep -c "Restart Claude Code"` | 2 (≥1) |
| Frontmatter unchanged | ✓ |
| Line count | 234 (≥80) |

## key-files

### created
- skills/skill-create/SKILL.md (body replaced)

### modified
- (none — frontmatter untouched)

## Deviations

None. All 9 stages match plan spec. Worked example uses `/skill-create a skill that summarizes git log output` traced through all stages as specified.
