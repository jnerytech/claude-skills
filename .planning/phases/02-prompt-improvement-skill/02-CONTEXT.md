# Phase 2: Prompt Improvement Skill - Context

**Gathered:** 2026-04-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Write the SKILL.md instruction body for `/improve-prompt` — a chat-only skill that takes a rough Claude Code prompt via `$ARGUMENTS`, rewrites it across four dimensions, and outputs the original, improved version, and a "what changed" annotation. No file writes, no external calls, no multi-turn interview. User gets one clean result immediately.

</domain>

<decisions>
## Implementation Decisions

### Output Layout (PROMPT-03)
- **D-01:** Use three `##` sections: `## Original`, `## Improved`, `## What Changed`. The original prompt is displayed in a fenced code block; the improved prompt is also in a fenced code block (makes it copyable). The `## What Changed` section is a bullet list, not a paragraph.
- **D-02:** Both the original and improved prompts go inside fenced code blocks — this makes them copyable and visually distinct from the annotation prose.

### "What Changed" Annotation (PROMPT-04)
- **D-03:** Each bullet in `## What Changed` follows the pattern: `- [Change label] — [one-sentence reason why it improves the prompt]`. Example: `- Added @file reference — gives Claude a precise entry point instead of searching the whole codebase`.
- **D-04:** Bullets only appear for changes that were actually made. If a dimension was already strong in the original, no bullet for it. Signal/noise ratio over exhaustive coverage.

### Idiom Injection Logic (PROMPT-05)
- **D-05:** Heuristic-based injection — each idiom fires only when its cue is present:
  - `@file` reference: inject when a filename, path, or module name is mentioned or clearly implied by the prompt. If the file is implied but not named (e.g. "auth middleware"), infer a plausible path (e.g. `@file auth/middleware.ts`).
  - Verification ask: inject when the task is a code change (fix, refactor, implement, migrate, etc.).
  - Scope bounds: inject when the prompt lacks clear success criteria or could be interpreted too broadly.
- **D-06:** When a filename is implied but not stated, infer a plausible `@file` path rather than omitting the reference. Claude at invocation time will correct wrong guesses; a concrete-but-approximate reference is more useful than no reference.

### Low-Info Input Handling
- **D-07:** Always produce a best-effort rewrite, even for vague inputs. Never ask a clarifying question before rewriting — that defeats the fast-turnaround purpose. For prompts that are too vague to rewrite with full specificity, use bracketed placeholders (`[describe symptom]`, `[specify the target file]`) to show what's missing structurally. Append a `⚠️ To sharpen further, add:` note after `## What Changed` listing what context would improve the rewrite.
- **D-08:** The "sharpen further" note is optional — only appear when the input was detectably low-information (short, no file references, no describable scope). Don't add it to already-decent prompts.

### Preserved from Phase 1
- **D-05 (Phase 1):** YAML frontmatter + Markdown body. Stub already has correct frontmatter — Phase 2 writes the body only.
- improve-prompt has `disable-model-invocation: true` and no `allowed-tools` (confirmed in stub — no file I/O needed).

### Claude's Discretion
- Exact heuristic thresholds for what counts as "code change" vs "explanation" task — Claude applies judgment based on verb/intent signals in the prompt.
- Ordering of `## What Changed` bullets — most impactful change first is preferred but not enforced.
- Whether to add a scope statement vs a verification ask when a prompt has one but not the other.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Roadmap
- `.planning/REQUIREMENTS.md` — PROMPT-01 through PROMPT-05 define all Phase 2 acceptance criteria
- `.planning/ROADMAP.md` — Phase 2 success criteria (5 numbered items under Prompt Improvement Skill)
- `.planning/PROJECT.md` — Core constraints: skill format, AskUserQuestion 4-option limit, Windows path requirement

### Research
- `.planning/research/FEATURES.md` — Prompt Improvement Skill section: table stakes, differentiators, anti-features, competitor analysis. Key findings: no multiple variants, no framework-based rewriting, Claude Code-native patterns only, verification criteria as highest-leverage improvement.

### Existing Code (Phase 2 edit target)
- `skills/improve-prompt/SKILL.md` — Stub with correct frontmatter already in place. Phase 2 writes the body only — do NOT change frontmatter fields.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `skills/improve-prompt/SKILL.md` stub — frontmatter is final (name, description, argument-hint, disable-model-invocation). Phase 2 replaces the placeholder body comments with working instructions.

### Established Patterns
- `$ARGUMENTS` substitution: the stub already has `The user invoked this with: $ARGUMENTS`. Phase 2 builds on this — the skill body reads `$ARGUMENTS` as the rough prompt to rewrite.
- No `allowed-tools` on this skill — improve-prompt is a pure reasoning/output skill. No Bash, Read, or Write calls in the body.
- SKILL.md body is Markdown instructions that Claude follows at invocation time. Instructions should be imperative and direct, not narrative.

### Integration Points
- No integration with other skills or phases — improve-prompt is standalone (confirmed in FEATURES.md cross-skill dependency chart).
- Output stays in chat — no file written, no state persisted between invocations.

</code_context>

<specifics>
## Specific Ideas

- The preview selected by the user during discussion is the canonical example of the desired output format:
  ```
  ## Original
  ```
  fix the auth bug
  ```

  ## Improved
  ```
  In auth/middleware.ts, the token expiry check
  uses `<` instead of `<=`. Fix it and run
  `npm test -- auth` to verify no regressions.
  ```

  ## What Changed
  - Added @file reference — gives Claude a precise entry point instead of searching the whole codebase
  - Added scope: narrowed to token expiry logic — prevents Claude from refactoring unrelated code
  - Added verification step — gives Claude a way to confirm its fix worked without being asked
  ```
- Low-info example (with "sharpen" note):
  ```
  ## Original
  fix the bug

  ## Improved
  Identify and fix the bug causing [describe symptom]. After fixing, run the relevant tests to confirm the regression is resolved.

  ## What Changed
  - Added symptom placeholder — Claude needs to know what's broken to find the right bug
  - Added verification step

  ⚠️ To sharpen further, add: which file or feature is affected, and what the expected vs actual behavior is.
  ```

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 2-Prompt Improvement Skill*
*Context gathered: 2026-04-27*
