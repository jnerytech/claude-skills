# Phase 2: Prompt Improvement Skill - Research

**Researched:** 2026-04-27
**Domain:** Claude Code SKILL.md instruction body authoring — pure-reasoning, chat-output skill
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Use three `##` sections: `## Original`, `## Improved`, `## What Changed`. The original prompt is displayed in a fenced code block; the improved prompt is also in a fenced code block. The `## What Changed` section is a bullet list, not a paragraph.

**D-02:** Both the original and improved prompts go inside fenced code blocks — this makes them copyable and visually distinct from the annotation prose.

**D-03:** Each bullet in `## What Changed` follows the pattern: `- [Change label] — [one-sentence reason why it improves the prompt]`. Example: `- Added @file reference — gives Claude a precise entry point instead of searching the whole codebase`.

**D-04:** Bullets only appear for changes that were actually made. If a dimension was already strong in the original, no bullet for it. Signal/noise ratio over exhaustive coverage.

**D-05:** Heuristic-based injection — each idiom fires only when its cue is present:
  - `@file` reference: inject when a filename, path, or module name is mentioned or clearly implied by the prompt. If the file is implied but not named (e.g. "auth middleware"), infer a plausible path (e.g. `@file auth/middleware.ts`).
  - Verification ask: inject when the task is a code change (fix, refactor, implement, migrate, etc.).
  - Scope bounds: inject when the prompt lacks clear success criteria or could be interpreted too broadly.

**D-06:** When a filename is implied but not stated, infer a plausible `@file` path rather than omitting the reference. Claude at invocation time will correct wrong guesses; a concrete-but-approximate reference is more useful than no reference.

**D-07:** Always produce a best-effort rewrite, even for vague inputs. Never ask a clarifying question before rewriting. For prompts that are too vague to rewrite with full specificity, use bracketed placeholders (`[describe symptom]`, `[specify the target file]`) to show what's missing structurally. Append a `⚠️ To sharpen further, add:` note after `## What Changed` listing what context would improve the rewrite.

**D-08:** The "sharpen further" note is optional — only appear when the input was detectably low-information (short, no file references, no describable scope). Don't add it to already-decent prompts.

**Phase 1 carry-forward:** YAML frontmatter + Markdown body. Stub has correct frontmatter (name, description, argument-hint, disable-model-invocation). Phase 2 writes the body only — do NOT change frontmatter fields.

**improve-prompt has `disable-model-invocation: true` and no `allowed-tools`** — confirmed in stub, no file I/O needed.

### Claude's Discretion

- Exact heuristic thresholds for what counts as "code change" vs "explanation" task — Claude applies judgment based on verb/intent signals in the prompt.
- Ordering of `## What Changed` bullets — most impactful change first is preferred but not enforced.
- Whether to add a scope statement vs a verification ask when a prompt has one but not the other.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROMPT-01 | User can invoke `/improve-prompt <rough-prompt>` and receive a rewritten version in chat (no file writes, no external dependencies) | Skill body uses $ARGUMENTS substitution; `disable-model-invocation: true` and no `allowed-tools` confirmed in stub |
| PROMPT-02 | Skill rewrites input optimizing for all four dimensions: clarity/specificity, context richness, structure, and scope/verification criteria | Four-dimension framework documented in FEATURES.md and official Claude Code best practices; instruction body encodes each dimension as an explicit reasoning step |
| PROMPT-03 | Output shows original prompt and improved prompt side by side in chat | D-01/D-02 locked layout: three `##` sections, both prompts in fenced code blocks — uses 4-backtick outer fence to prevent Markdown nesting breakage (see Pitfall 1 below) |
| PROMPT-04 | Output includes "what changed" annotation explaining each material improvement made | D-03/D-04 locked format: bullet list, label + reason, only for actual changes made |
| PROMPT-05 | Where appropriate, improved prompt contains Claude Code-specific idioms: `@file` references, explicit verification asks, scope bounds | D-05/D-06 heuristic injection logic locked; idioms fire on presence cues, not unconditionally |
</phase_requirements>

---

## Summary

Phase 2 is a single-file edit: replace the placeholder comment block in `skills/improve-prompt/SKILL.md` with a working instruction body. The frontmatter is final and must not be changed. The deliverable is pure prompt engineering — a Markdown instruction body that teaches Claude the four-dimension rewrite algorithm, the heuristic idiom injection rules, and the locked output layout, all in under 500 lines.

All user decisions (D-01 through D-08) are locked from the CONTEXT.md discussion session. The primary research findings that affect planning are: (1) the canonical output example in CONTEXT.md uses triple-backtick fenced blocks nested inside a Markdown document that is itself rendered as code — this requires a 4-backtick outer fence to avoid premature block termination; (2) SKILL.md body style is imperative with explanatory rationale ("do X because Y"), not narrative; (3) worked examples inside the body are standard and serve as few-shot guidance; (4) empty `$ARGUMENTS` (user invokes `/improve-prompt` alone) is not covered by D-07 and needs an explicit handling rule.

**Primary recommendation:** Write a compact, well-structured SKILL.md body (under 200 lines) using imperative instructions with brief reasoning, a worked example of the desired output format, and explicit heuristic tables for idiom injection. Use 4-backtick outer fences for all code block examples inside the body.

---

## Architectural Responsibility Map

This phase has no multi-tier architecture — it is a single-model-turn skill. The table below records the degenerate case explicitly.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Prompt ingestion | Skill body (Claude at invocation) | — | `$ARGUMENTS` substitution injects the rough prompt; no preprocessing layer exists |
| Rewrite reasoning | Skill body (Claude at invocation) | — | All four-dimension analysis happens in a single Claude turn; no pipeline |
| Output formatting | Skill body (Claude at invocation) | — | Three-section layout with fenced blocks is enforced by body instructions |
| Idiom injection | Skill body (Claude at invocation) | — | Heuristic rules are written as instructions Claude applies during reasoning |

---

## Standard Stack

### Core

| Library/Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SKILL.md format | Claude Code current | Skill entrypoint with YAML frontmatter + Markdown body | Plugin architecture requires this format; stub already exists |
| `$ARGUMENTS` substitution | Built-in | Passes user-typed rough prompt into skill body | Standard Claude Code mechanism for argument passing [VERIFIED: official docs] |
| `disable-model-invocation: true` | Built-in | User-only trigger — Claude cannot auto-invoke | Prevents unwanted rewrites; already set in stub [VERIFIED: official docs] |

### Supporting

No external libraries. No npm packages. No file I/O. This phase produces a text file.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| 4-backtick outer fence in body examples | Triple-backtick outer fence | Triple-backtick will prematurely close inner fences — broken rendering; 4-backtick is the standard fix [VERIFIED: CommonMark spec behavior, cross-confirmed via susam.net] |
| Inline worked example in SKILL.md body | Separate `examples/` file | One-turn skill invocation doesn't need supporting file loading; inline example keeps the body self-contained and avoids file-read overhead |

**Installation:** No installation. Phase 2 edits one existing file.

---

## Architecture Patterns

### System Architecture Diagram

```
User types: /improve-prompt <rough-prompt>
           │
           ▼
    Claude Code injects $ARGUMENTS
    into SKILL.md body content
           │
           ▼
    Claude reads full rendered body
    (frontmatter stripped by runtime)
           │
           ▼
    Claude reasons over body instructions:
    ┌─────────────────────────────────┐
    │ 1. Ingest $ARGUMENTS as input   │
    │ 2. Apply 4-dimension analysis   │
    │ 3. Run idiom injection heuristics│
    │ 4. Format 3-section output      │
    └─────────────────────────────────┘
           │
           ▼
    Chat output (no tool calls, no files):
    ## Original
    ## Improved
    ## What Changed
    [optional ⚠️ sharpen note]
```

### Recommended Project Structure

No new directories. Only one file changes:

```
skills/
└── improve-prompt/
    └── SKILL.md    ← Phase 2 replaces placeholder body
```

### Pattern 1: SKILL.md Body — Imperative with Reasoning

**What:** Instruction bodies use imperative directives accompanied by brief rationale explaining *why*, not just *what*. The official docs explicitly warn against ALWAYS/NEVER without context: "if you find yourself writing ALWAYS or NEVER in all caps, reframe and explain the reasoning." [CITED: code.claude.com/docs/en/skills]

**When to use:** Every instruction in the body.

**Example:**
```markdown
When the task mentions a file, add an `@file` reference to the improved prompt.
Do this even when the filename must be inferred — a plausible path like
`@file auth/middleware.ts` is more useful than no reference, because Claude
at invocation time will correct wrong guesses.
```

### Pattern 2: Inline Worked Example as Few-Shot Guidance

**What:** Include a worked example of the desired input/output pair inside the SKILL.md body. The model uses it as implicit few-shot guidance. [CITED: official skill docs — "It's useful to include examples."]

**When to use:** Any skill with a specific output format that could be misinterpreted.

**Example (note 4-backtick outer fence — see Pitfall 1):**

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
- Added @file reference — gives Claude a precise entry point
- Added scope: narrowed to token expiry logic — prevents unrelated refactoring
- Added verification step — gives Claude a way to confirm the fix worked
````

### Pattern 3: Heuristic Table for Idiom Injection

**What:** Encode conditional injection rules as a compact "if cue present → inject idiom" table. This is more reliable than prose because the model can scan it deterministically.

**When to use:** When the skill has multiple conditional behaviors that must not fire indiscriminately.

**Example:**
```markdown
Apply these idioms only when their cue is present:

| Idiom | Inject when | Example |
|-------|-------------|---------|
| `@file <path>` | Filename, path, or module name is mentioned or clearly implied | `@file src/auth/middleware.ts` |
| Verification ask | Task verb is fix, refactor, implement, migrate, add, or update | "Run `npm test` to confirm no regressions" |
| Scope bounds | No clear success criteria, or prompt could be interpreted too broadly | "Focus only on X; do not change Y" |
```

### Anti-Patterns to Avoid

- **Narrative instructions:** "The skill will analyze the prompt and..." — use "Analyze the prompt and..." instead. Narrative voice distances the instruction from the action. [CITED: official skill docs — "Prefer using the imperative form"]
- **Unconditional idiom injection:** Adding `@file`, verification, and scope bounds to every rewrite regardless of input creates noise for already-good prompts and violates D-04/D-05.
- **Nested triple-backtick fences in worked examples:** Inner ```` ``` ```` blocks inside a Markdown body that is itself displayed inside ```` ``` ```` will break rendering. Use 4-backtick outer fences for any examples that contain code blocks. (See Pitfall 1.)
- **Hardcoded framework labels (RISEN, CO-STAR, etc.):** These are designed for LLM API use, not Claude Code agentic tasks. Apply Claude Code-native patterns instead. [VERIFIED: FEATURES.md anti-feature table]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Argument passing | Custom parsing of `$ARGUMENTS` | Native `$ARGUMENTS` substitution | Built into Claude Code; no parsing needed; appended automatically if placeholder absent [VERIFIED: official docs] |
| Output formatting | Custom template renderer | Markdown sections in instruction body | Claude outputs Markdown natively; just specify the section structure |
| Idiom library | External reference file for `@file`/verification patterns | Inline heuristic table in body | Skill is one-turn, standalone; supporting files are unnecessary overhead |

**Key insight:** This phase is a prompt-engineering problem, not a software engineering problem. Nothing should be "built" — only written.

---

## Runtime State Inventory

SKIPPED — greenfield content phase. No rename, refactor, or migration involved. No runtime state to audit.

---

## Common Pitfalls

### Pitfall 1: Nested Triple-Backtick Fences Break Markdown Rendering

**What goes wrong:** The canonical output example (CONTEXT.md `<specifics>`) shows:

```
## Original
```
fix the auth bug
```
```

The inner triple-backtick fence will prematurely close the outer fence in any standard Markdown renderer. The user will not see a nested code block — they will see broken rendering with the interior content appearing as raw text outside the block.

**Why it happens:** CommonMark spec: a closing fence requires the same fence character (backtick or tilde) and at least as many markers as the opening fence. Three inner backticks terminate a three-backtick outer fence. [VERIFIED: CommonMark spec behavior; cross-confirmed at susam.net/nested-code-fences.html]

**How to avoid:** Use a 4-backtick outer fence whenever the content inside contains triple-backtick fences. The SKILL.md body must use this pattern for any worked examples it shows:

````markdown
## Original
```
fix the auth bug
```
````

The same rule applies to multi-line code-block injection syntax in SKILL.md (` ```! ` blocks). The 4-backtick convention is documented in the official Claude Code skills page examples. [CITED: code.claude.com/docs/en/skills — codebase-visualizer example uses 4-backtick outer fence]

**Warning signs:** Test the rendered SKILL.md in a Markdown previewer. If `## Improved` appears outside its code block or as plain prose, the fence escalation is missing.

**Resolution for the CONTEXT.md example:** The worked examples in the SKILL.md body should use 4-backtick outer fences. The CONTEXT.md `<specifics>` section captures the *desired output format*, not the encoding used to achieve it in SKILL.md.

**Runtime note:** At runtime, the model reads SKILL.md as raw text, not rendered Markdown. Claude produces its output as plain Markdown — lines like `## Original`, triple backtick, text, triple backtick — with no outer wrapper. This means user-visible chat rendering is always correct. The 4-backtick rule applies only to worked examples and documentation encoded *inside* SKILL.md, not to Claude's output.

---

### Pitfall 2: Empty `$ARGUMENTS` Not Handled

**What goes wrong:** D-07 specifies behavior for vague inputs (best-effort rewrite with bracketed placeholders). It does not specify what to do when the user invokes `/improve-prompt` with no argument at all — `$ARGUMENTS` expands to an empty string.

**Why it happens:** The CONTEXT.md discussion focused on "low-information" inputs (short, vague text), not the zero-input case.

**How to avoid:** Add an explicit guard at the top of the instruction body:

```markdown
If $ARGUMENTS is empty or contains only whitespace, output:
"Provide the rough prompt you want improved as an argument, for example:
`/improve-prompt fix the auth bug`"
Then stop — do not attempt a rewrite.
```

This is the smallest compliant behavior: one informative message, no multi-turn loop (consistent with D-07's "never ask a clarifying question before rewriting"). [ASSUMED — not locked in CONTEXT.md; planner should treat as a recommended addition]

---

### Pitfall 3: Frontmatter Mutation

**What goes wrong:** An implementer edits the SKILL.md and accidentally changes `disable-model-invocation: true` to false, or adds `allowed-tools`, or modifies `description`.

**Why it happens:** Phase 2 touches the same file as Phase 1. The stub frontmatter is final.

**How to avoid:** The plan must explicitly scope the edit to lines after the frontmatter closing `---`. The planner should include a verification step: after editing, confirm that `git diff` shows only body changes, not frontmatter changes.

**Warning signs:** `git diff skills/improve-prompt/SKILL.md` shows any change above the second `---` line.

---

### Pitfall 4: Instructions Too Abstract to Be Deterministic

**What goes wrong:** The body says "apply the four dimensions" without specifying what each dimension means in concrete terms. Claude interprets "context richness" differently on each invocation, producing inconsistent rewrites.

**Why it happens:** Authors assume the model infers the meaning of framework labels. Claude Code documentation and community implementations confirm this is unreliable for task-specific skills.

**How to avoid:** Define each dimension concretely in the body with an action verb:

- **Clarity/specificity:** Name the exact file, function, or behavior involved — eliminate pronouns like "it" or "that"
- **Context richness:** Add `@file` reference; include relevant constraint (language, framework, version)
- **Structure:** Use an imperative opening verb; separate "what to do" from "how to verify"
- **Scope/verification:** State what Claude should NOT change; specify how to confirm the task is done

---

## Code Examples

Verified patterns from official sources:

### SKILL.md Body — Task Skill Pattern (Official Docs)

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

Source: [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills) [VERIFIED]

### $ARGUMENTS Substitution Behavior (Official Docs)

- `$ARGUMENTS` expands to the full argument string as typed.
- If `$ARGUMENTS` is NOT present in the body, Claude Code appends `ARGUMENTS: <value>` to the end of the skill content automatically.
- Empty invocation: `$ARGUMENTS` expands to empty string — behavior is undefined by default; must be handled explicitly in body.

Source: [code.claude.com/docs/en/skills — Available string substitutions table](https://code.claude.com/docs/en/skills) [VERIFIED]

### 4-Backtick Outer Fence for Nested Code Blocks

````markdown
## Original
```
fix the auth bug
```

## Improved
```
In auth/middleware.ts, the token expiry check uses `<` instead of `<=`.
Fix it and run `npm test -- auth` to verify no regressions.
```
````

Source: CommonMark spec; verified at susam.net/nested-code-fences.html [VERIFIED]

### Skill Content Lifecycle (Important for Body Design)

"When you or Claude invoke a skill, the rendered SKILL.md content enters the conversation as a single message and stays there for the rest of the session. Claude Code does not re-read the skill file on later turns, so write guidance that should apply throughout a task as **standing instructions** rather than one-time steps."

Source: [code.claude.com/docs/en/skills — Skill content lifecycle](https://code.claude.com/docs/en/skills) [VERIFIED]

Implication for this skill: improve-prompt is invoked once, produces output, and is done. The body does not need "standing instruction" framing — it is a single-turn task. No special lifecycle handling required.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.claude/commands/<name>.md` flat file | `skills/<name>/SKILL.md` with directory | ~late 2025 | Both still work; skills add supporting files and frontmatter control. Stub uses skills format. |
| `<skill>` XML structure (early docs) | YAML frontmatter + Markdown body | Current | PROJECT.md notes this; stub already uses correct format |
| Generic "make it clearer" prompt frameworks | Claude Code-native idioms (@file, verification, scope) | N/A | FEATURES.md competitor analysis confirms Claude Code-native patterns outperform generic frameworks for this use case |

**Deprecated/outdated:**
- `<skill>` XML tags: Research from Phase 1 confirmed these are not the current format; YAML frontmatter is correct. [VERIFIED in Phase 1 — stub uses correct format]
- `.claude/commands/` path: still functional but skills format is recommended going forward. Not relevant here since plugin path is `skills/improve-prompt/SKILL.md`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Empty `$ARGUMENTS` expands to empty string (not undefined/error) | Common Pitfalls — Pitfall 2 | If Claude Code handles empty arguments differently (e.g., skips substitution), the guard condition may need adjustment — low risk, easily tested |
| A2 | Claude's chat renderer (where skill output appears) follows standard Markdown for fenced code blocks, making 4-backtick outer fence the correct fix | Common Pitfalls — Pitfall 1 | If Claude's output renderer has non-standard fence behavior, the nesting fix may not work — medium risk; can be verified by testing the rendered output |

**All other claims in this research are VERIFIED (official docs) or CITED (confirmed sources).**

---

## Open Questions (RESOLVED)

1. **Empty `$ARGUMENTS` exact behavior**
   - What we know: Official docs state `$ARGUMENTS` expands to the full argument string. If no argument is typed, the string is empty.
   - What's unclear: Whether Claude Code inserts a space or empty string vs. omits the substitution entirely.
   - RESOLVED: Add explicit empty-check guard to body (D-07 already covers vague inputs; zero-input is an adjacent case). The guard checks `empty or contains only whitespace`. Verify by testing `/improve-prompt` with no argument after implementation.

2. **How Claude renders output sections — are `##` headers rendered or shown raw?**
   - What we know: Skills output Markdown to chat. Claude Code chat renders Markdown.
   - What's unclear: Whether `## Original` renders as a bold header or is shown as `## Original` raw text in the terminal interface.
   - RESOLVED: No implementation change needed — use `##` headers as per D-01. If the user sees raw `##`, that is a rendering setting issue, not a skill issue. The plan proceeds with `##` headers per the locked decision.

---

## Environment Availability

SKIPPED — no external dependencies. This phase produces a Markdown text file. No tools, runtimes, databases, or CLI utilities are required beyond the git working directory.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual UAT (no automated framework applicable to instruction body content) |
| Config file | none |
| Quick run command | `cat skills/improve-prompt/SKILL.md` — verify body replaced |
| Full suite command | `/improve-prompt fix the auth bug` in Claude Code — verify output matches canonical example from CONTEXT.md |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROMPT-01 | Invocation with argument produces chat output, no file writes | smoke | `cat skills/improve-prompt/SKILL.md \| grep -c "## Original"` (must be >= 1) | ✅ |
| PROMPT-02 | Four dimensions applied | manual-only | invoke `/improve-prompt` with test prompt, inspect output | ❌ Wave 0 |
| PROMPT-03 | Original + Improved side by side in fenced blocks | structural | `grep "## Original\|## Improved\|## What Changed" skills/improve-prompt/SKILL.md` (must find all three) | ✅ |
| PROMPT-04 | What Changed bullet list with label + reason format | manual-only | invoke skill with test prompt, verify bullet format | ❌ Wave 0 |
| PROMPT-05 | Claude Code idioms injected heuristically | manual-only | invoke skill with "fix the auth bug", verify @file appears in output | ❌ Wave 0 |

**Manual-only justification:** PROMPT-02, PROMPT-04, PROMPT-05 test LLM reasoning behavior — whether Claude produces an actually improved prompt. No automated command can evaluate rewrite quality. These require human review against the canonical example in CONTEXT.md `<specifics>`.

### Sampling Rate

- **Per task commit:** `grep "## Original\|## Improved\|## What Changed" skills/improve-prompt/SKILL.md` — verify structure
- **Per wave merge:** Run the three UAT test cases from CONTEXT.md `<specifics>` manually
- **Phase gate:** Human-verified output matches canonical example before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `skills/improve-prompt/SKILL.md` body — the deliverable itself (empty/stub → working body). Phase 2 has exactly one plan: write this body.

---

## Security Domain

**`security_enforcement`** is not set to false in `.planning/config.json`. However, this skill has no security surface:

- No file writes (confirmed: no `allowed-tools`, `disable-model-invocation: true`)
- No network calls
- No credential handling
- No user data persistence
- Input is a user-supplied rough prompt — treated as bounded data per REQUIREMENTS.md "Out of Scope: Prompt injection protection"

**ASVS categories:**

| ASVS Category | Applies | Rationale |
|---------------|---------|-----------|
| V2 Authentication | No | No auth surface — skill outputs to chat |
| V3 Session Management | No | No state between invocations |
| V4 Access Control | No | No access-controlled resources |
| V5 Input Validation | No | User-supplied argument is passed directly to Claude as context — no code execution, no parseable structure to validate |
| V6 Cryptography | No | No secrets, no encryption |

**Conclusion:** No security controls required for this phase. The `Out of Scope` decision in REQUIREMENTS.md ("Prompt injection protection — User-supplied arguments are treated as bounded data by the skills platform") covers the only plausible concern.

---

## Sources

### Primary (HIGH confidence)
- [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills) — SKILL.md format, frontmatter reference, `$ARGUMENTS` substitution behavior, body style conventions, skill content lifecycle, nested code fence example in codebase-visualizer
- [susam.net/nested-code-fences.html](https://susam.net/nested-code-fences.html) — CommonMark spec confirmation of 4-backtick outer fence pattern

### Secondary (MEDIUM confidence)
- `.planning/research/FEATURES.md` — prior research: Claude Code-native idioms, anti-feature analysis, competitor comparison. VERIFIED against official docs during Phase 1.
- `.planning/phases/02-prompt-improvement-skill/02-CONTEXT.md` — locked user decisions D-01 through D-08, canonical output examples, discretion areas

### Tertiary (LOW confidence — flagged in Assumptions Log)
- A1, A2 above: empty `$ARGUMENTS` behavior and renderer fence handling — not directly testable without live invocation

---

## Metadata

**Confidence breakdown:**
- Standard stack (skill format, substitutions): HIGH — verified against official docs
- Architecture (body style, worked examples): HIGH — verified against official docs and prior research
- Pitfalls (nested fences, empty args): HIGH for fence issue (spec-verified); MEDIUM for empty args (behavior assumed from docs)
- Output format decisions: HIGH — locked in CONTEXT.md

**Research date:** 2026-04-27
**Valid until:** 2026-06-01 (stable — SKILL.md format changes infrequently; recheck if Claude Code version bumps above v2.2.x)
