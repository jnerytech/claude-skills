# Phase 3: Skill Creator Skill - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-27
**Phase:** 3-Skill Creator Skill
**Areas discussed:** Interview structure, Doc reading source, Skill name resolution

---

## Interview structure

### Q1 — Pacing

| Option | Description | Selected |
|--------|-------------|----------|
| Adaptive | Claude reads argument first, infers what it can, asks only about genuinely ambiguous aspects. Fewer questions for clear requests. | ✓ |
| Fixed linear | Always ask the same 5-6 questions in the same order regardless of argument. | |
| Two-stage | Stage 1: one broad framing question. Stage 2: 3-4 targeted questions shaped by stage 1. | |

**User's choice:** Adaptive  
**Notes:** None.

---

### Q2 — Proposed answer format

| Option | Description | Selected |
|--------|-------------|----------|
| AskUserQuestion options | Each question uses AskUserQuestion with 2-3 concrete option labels + descriptions. User picks or selects Other for freeform. Consistent UX with 4-option hard limit. | ✓ |
| Inline proposals in chat | Numbered list in markdown, user types reply. No AskUserQuestion. | |
| Hybrid | AskUserQuestion for structured choices, freeform for creative things. | |

**User's choice:** AskUserQuestion options  
**Notes:** None.

---

### Q3 — Topics to cover (multiSelect)

| Option | Description | Selected |
|--------|-------------|----------|
| Trigger pattern | When should Claude invoke automatically vs user-invoked only (disable-model-invocation choice). | ✓ |
| Tools needed | Which tools the skill needs — shapes allowed-tools frontmatter. | ✓ |
| Output destination | Does skill write files, output to chat, or both. | ✓ |
| Edge cases / guards | What happens on empty args, bad input, missing context. | ✓ |

**User's choice:** All four topics  
**Notes:** Session interrupted by power outage after this question. Resumed next session.

---

## Doc reading source

### Q1 — What to read

| Option | Description | Selected |
|--------|-------------|----------|
| references/ only | Rely on 4 pre-loaded reference files. No user setup needed. | ✓ |
| docs/ only | Explicitly Read docs/index.md then specific topic files. Requires user setup. | |
| references/ + docs/ if present | Always use references/. Also read from docs/ when topic files exist. | |

**User's choice:** references/ only  
**Notes:** Supersedes the literal `${CLAUDE_SKILL_DIR}/docs/` wording in SKILL-02; intent is satisfied.

---

### Q2 — Selective vs. full read

| Option | Description | Selected |
|--------|-------------|----------|
| Select relevant subset | Read skills doc always. Read hooks/subagents/programmatic only if interview reveals need. | ✓ |
| Always read all 4 | Read all 4 reference files every invocation. Simpler but heavier context. | |

**User's choice:** Select relevant subset  
**Notes:** None.

---

### Q3 — Read timing

| Option | Description | Selected |
|--------|-------------|----------|
| Before interview | Read skills doc first, then start interview. Questions grounded in actual frontmatter fields. | ✓ |
| After interview | Interview first, then read only refs relevant to user's answers. | |

**User's choice:** Before interview  
**Notes:** None.

---

## Skill name resolution

### Q1 — How name is determined

| Option | Description | Selected |
|--------|-------------|----------|
| Claude infers + confirms | Claude derives kebab-case name from description, proposes as first step. User accepts or changes. | ✓ |
| User names it explicitly | Q1 is always "What should this skill be named?" Claude proposes 2-3 name options. | |
| From argument structure | First kebab-case token = name; rest = description. If no kebab token, Claude infers. | |

**User's choice:** Claude infers + confirms  
**Notes:** None.

---

### Q2 — When confirmation happens

| Option | Description | Selected |
|--------|-------------|----------|
| Before interview questions | Name confirmed first, then interview proceeds. No rename at preview. | ✓ |
| At preview/confirmation step | Interview runs, then name shown in frontmatter at review time. | |

**User's choice:** Before interview questions  
**Notes:** None.

---

## Claude's Discretion

- Adaptive threshold for how many questions to skip when argument is highly detailed
- Exact wording of AskUserQuestion option labels and descriptions
- Whether to show generated SKILL.md as single fenced block or split by frontmatter + body
- Standard empty-args guard output text (model after improve-prompt's guard)
- Preview/edit loop iteration depth before write

## Deferred Ideas

- `docs/index.md` may need an update to reflect that `references/` supersedes the download instructions — deferred to Phase 4 or cleanup
