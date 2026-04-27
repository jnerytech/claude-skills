# Phase 3: Skill Creator Skill - Pattern Map

**Mapped:** 2026-04-27
**Files analyzed:** 1 (one file modified — skill body prose replaces stub placeholder)
**Analogs found:** 1 / 1 (partial match — same role, different data flow)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `skills/skill-create/SKILL.md` (body only) | skill body (instruction prose) | interactive multi-stage workflow: read-refs → interview → generate → preview → write | `skills/improve-prompt/SKILL.md` | partial — same role and section structure; different data flow (improve-prompt is one-shot, skill-create is multi-stage interactive with tool calls) |

---

## Pattern Assignments

### `skills/skill-create/SKILL.md` body (skill body, interactive multi-stage workflow)

**Analog:** `skills/improve-prompt/SKILL.md`

The body replaces the `<!--` placeholder comment block at lines 11-20 of the stub. The `# Skill Create` H1 on line 9 is real content — keep it. Frontmatter (lines 1-7) is final — do NOT modify it.

The skill body is organized as a linear sequence of numbered stages. For each stage below, the pattern source is identified: either an excerpt from `skills/improve-prompt/SKILL.md` (analog) or RESEARCH.md (no analog in codebase).

---

#### Stage 1: Empty-args guard

**Pattern source:** `skills/improve-prompt/SKILL.md` lines 10-21

```markdown
The user invoked this with: $ARGUMENTS

## When to act

If `$ARGUMENTS` is empty or contains only whitespace, output exactly:

> Provide the rough prompt you want improved as an argument, for example:
> `/improve-prompt fix the auth bug`

Then stop — do not attempt a rewrite, do not ask a clarifying question.

Otherwise, treat everything in `$ARGUMENTS` as the rough prompt the user wants rewritten, and proceed.
```

**Adaptation for skill-create:** Copy the guard shape verbatim. Change the example invocation line to:

```
> `/skill-create a slash command that summarizes git logs`
```

Replace the "otherwise" instruction: instead of "proceed with rewrite", instruction is "proceed to Stage 2 (read references)."

---

#### Stage 2: Read references before interview

**Pattern source:** RESEARCH.md Pattern 5 (Architecture Patterns) — no analog in improve-prompt (which never calls Read)

Instruction shape to encode in skill body:

```markdown
## Read references

Before asking any interview question, read:

  Read `${CLAUDE_SKILL_DIR}/references/extend-claude-with-skills.md`

This grounds your knowledge of frontmatter fields, invocation control, AskUserQuestion
constraints, and `$ARGUMENTS` substitution before you propose anything.
```

Key constraint to state explicitly: Read happens before the first AskUserQuestion call. This is a numbered step, not implied behavior.

**`${CLAUDE_SKILL_DIR}` substitution:** Defined in `skills/skill-create/references/extend-claude-with-skills.md` line 229 (frontmatter reference table). The variable resolves to the skill's directory at runtime — use it in all Read calls referencing files in `references/`.

---

#### Stage 3: Name inference and confirmation

**Pattern source:** RESEARCH.md Pattern (Architecture Patterns, Stage 3) — no analog in improve-prompt

Instruction shape to encode:

```markdown
## Infer and confirm skill name

Infer a kebab-case name from `$ARGUMENTS`. Propose it before any interview question:

  "I'd name this `<inferred-name>` — change it?"

Use AskUserQuestion with exactly 2 explicit options:
  - "Yes, use this name"
  - "Enter a different name" (user provides freeform)

(Platform appends "Other" automatically — total options = 3, within the 4-option hard limit.)

The name is confirmed here and does not change again. Use it in the frontmatter and write path
for the rest of the workflow.
```

---

#### Stage 4: Adaptive interview (four required topics)

**Pattern source:** RESEARCH.md Pattern 2 (AskUserQuestion with ≤3 explicit options) — no analog in improve-prompt (improve-prompt explicitly forbids clarifying questions, line 50)

Instruction shape — one AskUserQuestion per topic, skip only when `$ARGUMENTS` clearly resolves the topic:

```markdown
## Interview

Ask about these four topics in order. Skip a question only when `$ARGUMENTS` unambiguously
answers it. Each AskUserQuestion uses ≤3 explicit options — the platform appends "Other"
automatically, keeping the total at or under 4.

**Topic 1 — Trigger pattern**
Question: "Should Claude invoke this skill automatically, or only when you type /name?"
Options (≤3 explicit):
  - "User-only slash command" — adds `disable-model-invocation: true`; best for side-effectful workflows
  - "Claude auto-invokes" — no restriction; best for reference/knowledge skills
  - "Propose based on description" — Claude decides from context

**Topic 2 — Tools needed**
Question: "Which tools does this skill need to call?"
Options (≤3 explicit, propose based on description):
  - "Read/Grep/Glob only" — read-only exploration skills
  - "Bash + Write" — skills that run commands or write files
  - "Propose based on description" — Claude selects from frontmatter `allowed-tools` values

**Topic 3 — Output destination**
Question: "Where does this skill send its output?"
Options (≤3 explicit):
  - "Chat output only" — no file writes needed
  - "Writes a file" — adds Write (and Bash for mkdir) to allowed-tools
  - "Both chat and file" — combines the above

**Topic 4 — Edge cases and guards**
Question: "What should the skill do when invoked with no arguments or bad input?"
Options (≤3 explicit):
  - "Stop with a usage message" — same guard pattern as improve-prompt
  - "Proceed with defaults" — attempt the task with sensible fallback values
  - "Ask for clarification" — use AskUserQuestion before proceeding
```

---

#### Stage 5: Conditional reference reads

**Pattern source:** RESEARCH.md Architecture Patterns (Stage 5) — no analog in improve-prompt

After the interview, read additional reference files only if the interview answers indicate the need:

```markdown
## Conditional reference reads

After the interview is complete, read additional reference docs only when the interview
revealed a corresponding need:

- If user's skill needs hook-based automation:
    Read `${CLAUDE_SKILL_DIR}/references/automate-workflows-with-hooks.md`
- If user's skill needs subagent dispatch:
    Read `${CLAUDE_SKILL_DIR}/references/create-custom-subagents.md`
- If user's skill needs programmatic API calls:
    Read `${CLAUDE_SKILL_DIR}/references/run-claude-code-programmatically.md`

Decision rules:
  - hooks ref: triggered when Topic 1 answer selects user-only command with hook triggers,
    or when Topic 2 answer includes Bash(hook*)
  - subagents ref: triggered when Topic 3 answer selects subagent/fork output
  - programmatic ref: triggered when invocation context mentions CI or script use
```

---

#### Stage 6: Generate SKILL.md content in memory

**Pattern source:** RESEARCH.md Code Examples (SKILL.md Frontmatter Template Shape) — no structural analog in improve-prompt

Frontmatter template to encode in skill body instructions:

```yaml
---
name: <kebab-case-name confirmed in Stage 3>
description: "<what it does and when to use it — front-load key use case>"
argument-hint: [<hint>]
allowed-tools: [<tools from Topic 2 and 3 interview answers>]
disable-model-invocation: <true|false from Topic 1 interview answer>
---
```

Instruction to Claude: generate the full SKILL.md in memory — frontmatter + instruction body grounded in reference docs read in Stages 2 and 5. Do not write it to disk yet.

---

#### Stage 7: Preview — 4-backtick fence

**Pattern source:** `skills/improve-prompt/SKILL.md` lines 84-105 (worked example encoding)

The 4-backtick outer fence is used in improve-prompt to encode inner triple-backtick fences without breaking the outer fence. Apply the same technique to preview the generated SKILL.md:

```markdown
From improve-prompt lines 84-88 (pattern shape):

````markdown
## Original
```
[user's rough prompt — verbatim]
```
````
```

**Adaptation for skill-create:** Wrap the entire generated SKILL.md (frontmatter + body) in a 4-backtick outer fence for the preview. Line 105 of improve-prompt contains the explanatory note: "The 4-backtick fence above is only how this example is encoded inside SKILL.md so the inner triple-backticks render correctly." Include an equivalent note in the skill body.

After the preview, ask in chat (not via AskUserQuestion): "Write it?" The user responds in chat. Do not use AskUserQuestion for this confirmation — it adds friction after a long interview.

---

#### Stage 8: Validate, mkdir, and Write

**Pattern source:** RESEARCH.md Pattern 3 (Windows Write Path) and Pitfall 4 (Write Without mkdir -p) — no analog in improve-prompt (which explicitly writes nothing, line 138)

Instruction sequence to encode:

```markdown
## Write the skill

1. Validate the confirmed name before any file operation:
   - Must match `^[a-z0-9]+(-[a-z0-9]+)*$`
   - Must not contain `/`, `..`, or `\`
   If validation fails, output an error and stop — do not run mkdir or Write.

2. Run Bash to resolve the path and create the directory:
   ```bash
   SKILL_DIR="$USERPROFILE/.claude/skills/<validated-name>"
   mkdir -p "$SKILL_DIR"
   ```
   Use `$USERPROFILE`, not `~`. The Write tool does not expand `~` on Windows.

3. Write the generated content:
   Write to `$SKILL_DIR/SKILL.md` with the generated SKILL.md content from Stage 6.

4. Confirm in chat:
   "Written to $USERPROFILE/.claude/skills/<name>/SKILL.md"
```

---

#### Stage 9: Final checks (section structure from improve-prompt)

**Pattern source:** `skills/improve-prompt/SKILL.md` lines 129-138

```markdown
## Final checks before responding

Before sending output, confirm:
1. Three `##` sections are present in this exact order: Original, Improved, What Changed.
2. The Original section contains the user's input verbatim, inside a fenced code block.
...
7. No file was written; no tool was invoked. The output is chat-only.
```

**Adaptation for skill-create:** Copy the "Final checks before responding" section pattern. Replace improve-prompt-specific items with skill-create-specific checklist:

```markdown
## Final checks before writing

Before executing the write step, confirm:
1. Name is confirmed (Stage 3) and validated (^[a-z0-9]+(-[a-z0-9]+)*$ + no /, .., \).
2. `extend-claude-with-skills.md` was read before the first AskUserQuestion call.
3. All four interview topics (trigger, tools, output, guards) were covered or consciously skipped.
4. Each AskUserQuestion call used ≤3 explicit options.
5. Generated SKILL.md was shown to user in a 4-backtick fence before writing.
6. User confirmed "Write it?" in chat.
7. `mkdir -p` ran before the Write call.
8. `$USERPROFILE` was used — not `~`.
```

---

#### Imperative section structure (cross-cutting)

**Pattern source:** `skills/improve-prompt/SKILL.md` overall structure (lines 1-139)

improve-prompt establishes the prose conventions all skills in this codebase follow:

- Section headings use `##`, written in imperative ("When to act", "How to rewrite")
- Instructions are second-person imperative to Claude ("Apply", "Output", "Read", "Write")
- Numbered lists for sequential steps; bullets for non-sequential options or definitions
- Worked example encoded in a 4-backtick outer fence with an explanatory note after it
- "Final checks" section is a numbered checklist, last section in the file

---

## Shared Patterns

### Section heading style
**Source:** `skills/improve-prompt/SKILL.md` line 8 (`# Improve Prompt`), lines 13, 24, 35, 47, 58, 84, 107, 129
**Apply to:** skill-create body
```markdown
# Skill Create

The user invoked this with: $ARGUMENTS

## When to act
...
## How to [stage name]
...
## Final checks before writing
```

### 4-backtick outer fence for embedded SKILL.md content
**Source:** `skills/improve-prompt/SKILL.md` lines 62-76 (format example), lines 84-103 (worked example)
**Apply to:** Stage 7 preview step and any worked examples in skill-create body

````markdown
````markdown
---
name: example-skill
...
---

[body]
````
````

(Outer fence is 4 backticks; inner fences in the generated content are 3 backticks — they don't terminate the outer fence.)

### AskUserQuestion hard limit: ≤3 explicit options
**Source:** CONTEXT.md D-02; `./CLAUDE.md` key constraints
**Apply to:** All AskUserQuestion calls in Stages 3 and 4
Statement to embed in skill body: "each AskUserQuestion call uses ≤3 explicit options (platform appends 'Other' automatically — total must not exceed 4)."

### $USERPROFILE path resolution
**Source:** RESEARCH.md Pattern 3; CONTEXT.md D-09
**Apply to:** Stage 8 write step only
```bash
SKILL_DIR="$USERPROFILE/.claude/skills/$NAME"
mkdir -p "$SKILL_DIR"
# Then Write to "$SKILL_DIR/SKILL.md"
```

---

## No Analog Found

The following capabilities have no existing analog in the codebase. The planner must use RESEARCH.md patterns for these:

| Stage | Capability | Reason | RESEARCH.md Reference |
|-------|-----------|--------|----------------------|
| Stage 2 | Read `${CLAUDE_SKILL_DIR}/references/` before interview | improve-prompt never calls Read | Pattern 5 (Instruction Body Structure), Stage 2 description |
| Stage 3 | AskUserQuestion for name confirmation | improve-prompt explicitly forbids clarifying questions (line 50) | Architecture Patterns, Stage 3 |
| Stage 4 | AskUserQuestion interview bank (4 topics) | improve-prompt explicitly forbids clarifying questions | Pattern 2 (AskUserQuestion with ≤3 explicit options) |
| Stage 5 | Conditional reference reads after interview | No existing skill reads conditionally | Architecture Patterns, Stage 5 |
| Stage 6 | Generate SKILL.md frontmatter + body in memory | improve-prompt outputs prose, not YAML+Markdown | Code Examples: SKILL.md Frontmatter Template Shape |
| Stage 8 | `mkdir -p` + Write to `$USERPROFILE` path | improve-prompt writes nothing (line 138) | Pattern 3 (Windows Write Path), Pitfall 4 (Write Without mkdir -p) |
| Stage 8 | Kebab-case + path-traversal name validation | No existing skill validates user-provided paths | Code Examples: Kebab-Case Validation in Bash |

---

## Metadata

**Analog search scope:** `skills/` directory — all SKILL.md files (`improve-prompt`, `skill-create` stub, `workspace-create` stub)
**Files scanned:** 3 SKILL.md files + 1 reference doc (`extend-claude-with-skills.md`)
**Analog selected:** `skills/improve-prompt/SKILL.md` — only complete working skill body in the codebase
**Pattern extraction date:** 2026-04-27

**Key constraint reminder for planner:**
- Do NOT modify frontmatter in `skills/skill-create/SKILL.md` (lines 1-7 are final)
- Replace only the `<!--` placeholder comment block (lines 11-20 of current stub); keep the `# Skill Create` H1 on line 9
- The skill body is pure Markdown prose — no code files, no tests, no new repo files
