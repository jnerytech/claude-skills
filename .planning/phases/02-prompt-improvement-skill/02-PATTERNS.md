# Phase 2: Prompt Improvement Skill - Pattern Map

**Mapped:** 2026-04-27
**Files analyzed:** 1 modified file
**Analogs found:** 1 / 1 (in-repo reference docs; no completed skill body exists in-repo)

---

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `skills/improve-prompt/SKILL.md` (body only) | command-skill | request-response | `skills/skill-create/references/extend-claude-with-skills.md` lines 280-293 (`deploy` task skill) + lines 338-352 (`fix-issue` skill with `$ARGUMENTS`) | role-match |

**Constraint: frontmatter is frozen.** Lines 1-6 of `skills/improve-prompt/SKILL.md` must not be changed. Phase 2 replaces only the body (lines 8-19, from the `# Improve Prompt` header down through the placeholder comment block).

---

## Pattern Assignments

### `skills/improve-prompt/SKILL.md` — body only (command-skill, request-response)

**Analog 1:** `skills/skill-create/references/extend-claude-with-skills.md` lines 280-293

**Task skill pattern with `$ARGUMENTS` — the canonical model for this file's body structure:**

```yaml
---
name: deploy
description: Deploy the application to production
disable-model-invocation: true
---

Deploy $ARGUMENTS to production:

1. Run the test suite
2. Build the application
3. Push to the deployment target
4. Verify the deployment succeeded
```

Key structural observations:
- The body opens with a single action-oriented sentence referencing `$ARGUMENTS` directly
- Imperative numbered steps follow — no narrative framing
- No "Introduction" or "Background" section — instructions start immediately

---

**Analog 2:** `skills/skill-create/references/extend-claude-with-skills.md` lines 338-352

**`$ARGUMENTS` intake as inline content (not a labelled block):**

```yaml
---
name: fix-issue
description: Fix a GitHub issue
disable-model-invocation: true
---

Fix GitHub issue $ARGUMENTS following our coding standards.

1. Read the issue description
2. Understand the requirements
3. Implement the fix
4. Write tests
5. Create a commit
```

The existing stub already uses this pattern at line 10: `The user invoked this with: $ARGUMENTS`. The Phase 2 body builds on that line — it is the intake, and the instructions that follow tell Claude what to do with it.

---

**Analog 3:** `skills/skill-create/references/extend-claude-with-skills.md` lines 153-163

**Reference skill with conditional rules (imperative + reasoning, no numbered steps):**

```yaml
---
name: api-conventions
description: API design patterns for this codebase
---

When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
- Include request validation
```

This pattern shows how to write conditional/heuristic rules as bullet lists under a `When <condition>:` clause — directly applicable to improve-prompt's idiom injection logic (D-05).

---

**In-repo stub showing current state** (`skills/improve-prompt/SKILL.md` lines 1-19):

The frontmatter (lines 1-6) is final:
```yaml
---
name: improve-prompt
description: "Rewrites a rough prompt for clarity, specificity, context richness, and structure. Use when the user invokes /improve-prompt or asks to 'improve this prompt', 'rewrite this prompt', or 'make this prompt clearer'. Do NOT use for general writing improvements unrelated to Claude Code prompts."
argument-hint: <rough-prompt-text>
disable-model-invocation: true
---
```

The body (lines 8-19) is the edit target. Lines 12-19 (placeholder comment block) are replaced entirely. Line 10 (`The user invoked this with: $ARGUMENTS`) is the intake anchor — keep it, build below it.

---

## SKILL.md Body Structural Patterns

These patterns come from RESEARCH.md, confirmed against reference doc analogs above. The planner copies these patterns into the instruction body.

### Pattern 1: Imperative with Reasoning

**Source:** `skills/skill-create/references/extend-claude-with-skills.md` lines 159-163 (api-conventions body); RESEARCH.md Pattern 1
**Apply to:** Every instruction rule in the body

Form: `[Imperative verb] [what]. Do this [even when / because] [rationale].`

Example from RESEARCH.md Pattern 1 (verbatim, for planner reference):
```
When the task mentions a file, add an `@file` reference to the improved prompt.
Do this even when the filename must be inferred — a plausible path like
`@file auth/middleware.ts` is more useful than no reference, because Claude
at invocation time will correct wrong guesses.
```

### Pattern 2: Inline Worked Example as Few-Shot Guidance

**Source:** RESEARCH.md Pattern 2; `skills/skill-create/references/extend-claude-with-skills.md` lines 338-352 (`fix-issue` shows inline example of `$ARGUMENTS` substitution result)
**Apply to:** The worked output example inside the body

The output example must use 4-backtick outer fences to prevent triple-backtick inner fences from breaking Markdown rendering (RESEARCH.md Pitfall 1). The planner must apply this when embedding the canonical example from CONTEXT.md `<specifics>`.

Correct encoding inside SKILL.md:

````markdown
**Example output:**

## Original
```
fix the auth bug
```

## Improved
```
In auth/middleware.ts, the token expiry check uses `<` instead of `<=`.
Fix it and run `npm test -- auth` to verify no regressions.
```

## What Changed
- Added @file reference — gives Claude a precise entry point instead of searching the whole codebase
- Added scope: narrowed to token expiry logic — prevents Claude from refactoring unrelated code
- Added verification step — gives Claude a way to confirm its fix worked without being asked
````

### Pattern 3: Heuristic Table for Conditional Injection

**Source:** RESEARCH.md Pattern 3; `skills/skill-create/references/extend-claude-with-skills.md` lines 159-163 (`When writing API endpoints:` conditional bullets)
**Apply to:** Idiom injection rules (D-05/D-06)

Encode "if cue present → inject idiom" as a compact table. This is more reliable than prose for multiple conditional behaviors that must not fire indiscriminately.

```markdown
Apply these idioms only when their cue is present:

| Idiom | Inject when | Example |
|-------|-------------|---------|
| `@file <path>` | Filename, path, or module name is mentioned or clearly implied | `@file src/auth/middleware.ts` |
| Verification ask | Task verb is fix, refactor, implement, migrate, add, or update | "Run `npm test` to confirm no regressions" |
| Scope bounds | No clear success criteria, or prompt could be interpreted too broadly | "Focus only on X; do not change Y" |
```

---

## Shared Patterns

### `$ARGUMENTS` Intake Line

**Source:** `skills/improve-prompt/SKILL.md` line 10 (existing stub); established from Phase 1 PATTERNS.md Shared Patterns section `$ARGUMENTS` Intake Pattern
**Apply to:** The improve-prompt body (already in place — preserve it)

```markdown
The user invoked this with: $ARGUMENTS
```

This line is the intake anchor. The body instructions that follow operate on `$ARGUMENTS` as the rough prompt to rewrite.

### Empty `$ARGUMENTS` Guard

**Source:** RESEARCH.md Pitfall 2 (recommended addition — not locked in CONTEXT.md but strongly advised)
**Apply to:** Top of the instruction body, immediately after the intake line

```markdown
If $ARGUMENTS is empty or contains only whitespace, output:
"Provide the rough prompt you want improved as an argument, for example:
`/improve-prompt fix the auth bug`"
Then stop — do not attempt a rewrite.
```

### Three-Section Output Layout

**Source:** CONTEXT.md D-01 and D-02 (locked decisions)
**Apply to:** The output format instructions in the body

```markdown
Output exactly three `##` sections in this order:

## Original
[rough prompt in a fenced code block]

## Improved
[rewritten prompt in a fenced code block]

## What Changed
[bullet list — each bullet: `- [Change label] — [one-sentence reason]`]
```

Bullets appear only for changes actually made (D-04). If a dimension was already strong in the original, omit its bullet.

### Optional Sharpen Note

**Source:** CONTEXT.md D-07 and D-08 (locked decisions)
**Apply to:** Appended after `## What Changed` when input is detectably low-information

```markdown
⚠️ To sharpen further, add: [comma-separated list of missing context]
```

Only emit when the input was short, had no file references, and had no describable scope. Do not add it to already-decent prompts.

### Frontmatter Freeze

**Source:** RESEARCH.md Pitfall 3; Phase 1 PATTERNS.md
**Apply to:** Verification step in the plan

The plan must scope edits to lines after the second `---` marker. Verification: `git diff skills/improve-prompt/SKILL.md` must show zero changes above the second `---` line.

---

## No Analog Found

No completed SKILL.md instruction body exists anywhere in this repository — both other skills (`skill-create`, `workspace-create`) are stubs. The reference docs provide structural patterns for task skill bodies, but no analog for the specific four-dimension rewrite algorithm, heuristic injection, or three-section output format. For those specifics, the planner must use RESEARCH.md Patterns 1/2/3 and Code Examples section directly.

| Aspect | Reason |
|--------|--------|
| Four-dimension rewrite algorithm (clarity, context, structure, scope) | No existing skill in this repo performs a structured rewrite; derived from RESEARCH.md Pitfall 4 and REQUIREMENTS.md PROMPT-02 |
| Three-section output layout (`## Original / ## Improved / ## What Changed`) | No analog; derived from CONTEXT.md D-01/D-02 (locked) |
| Low-info input handling with bracketed placeholders | No analog; derived from CONTEXT.md D-07/D-08 (locked) |

---

## Metadata

**Analog search scope:** `skills/` (all SKILL.md files), `skills/skill-create/references/` (four reference docs)
**Files scanned:** 7 (3 SKILL.md stubs + 4 reference docs)
**Strong analogs used:** `extend-claude-with-skills.md` — `deploy` pattern (lines 280-293), `fix-issue` pattern (lines 338-352), `api-conventions` pattern (lines 153-163)
**Pattern extraction date:** 2026-04-27

**Note on analog quality:** All in-repo SKILL.md files are Phase 1 stubs (no body content). The reference docs contain the only real skill body examples in this repository, making them the strongest available analogs despite being documentation rather than production code.
