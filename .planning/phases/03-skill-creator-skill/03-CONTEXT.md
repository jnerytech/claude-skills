# Phase 3: Skill Creator Skill - Context

**Gathered:** 2026-04-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Write the SKILL.md instruction body for `/skill-create` — a user-invoked skill that: infers a kebab-case skill name from `$ARGUMENTS` and confirms it, reads Claude Code reference docs before interviewing, conducts an adaptive 5-6 question interview (via AskUserQuestion options), generates a SKILL.md for review, then writes it globally to `$USERPROFILE/.claude/skills/<name>/SKILL.md`. No file reads outside the skill's own `references/` dir. No external network calls.

</domain>

<decisions>
## Implementation Decisions

### Interview Structure (SKILL-01, SKILL-03)
- **D-01:** Adaptive pacing — Claude reads `$ARGUMENTS` first, infers what it can, asks only about genuinely ambiguous aspects. Clear requests get fewer questions; vague descriptions get more (up to 5-6 total including name confirmation).
- **D-02:** Proposed answers use AskUserQuestion options (2-3 concrete labels + descriptions per question). "Other" auto-provided for freeform. 4-option hard limit applies — never design a question bank that exceeds 3 explicit options.
- **D-03:** Four required interview topics — always cover these regardless of how clear the argument is:
  1. **Trigger pattern** — auto-invoked by Claude (model-invoked) vs. user-only slash command (`disable-model-invocation: true`). Propose the right default based on description.
  2. **Tools needed** — which tools the skill body will call (shapes `allowed-tools` frontmatter). Propose based on what the description implies.
  3. **Output destination** — chat output only, file write, or both. Determines if Write/Bash are needed.
  4. **Edge cases / guards** — what happens on empty `$ARGUMENTS`, bad input, or missing context. Propose a standard guard pattern as the default.

### Doc Reading Source (SKILL-02)
- **D-04:** Read from `references/` dir only — the 4 pre-loaded files already in `skills/skill-create/references/`. No user doc-download setup required. This supersedes the literal `${CLAUDE_SKILL_DIR}/docs/` wording in SKILL-02; the intent (ground generation in local Claude Code docs) is satisfied by references/.
- **D-05:** Selective reading — always read `extend-claude-with-skills.md` first (covers skill anatomy, frontmatter fields, invocation control, dynamic context). Read `automate-workflows-with-hooks.md`, `create-custom-subagents.md`, and `run-claude-code-programmatically.md` only when the interview reveals the user's skill needs those capabilities.
- **D-06:** Read before interview — reference docs loaded before the first interview question so Claude's proposed options are grounded in actual frontmatter fields and capability names.

### Skill Name Resolution (SKILL-01)
- **D-07:** Claude infers a kebab-case name from the description and proposes it before the interview questions begin. Format: `"I'd name this \`skill-name\` — change it?"` User accepts or provides a freeform name. Name must be validated: kebab-case only, no path traversal chars (`/`, `..`, `\`).
- **D-08:** Name confirmed before interview questions proceed — no rename at the preview/confirmation step. The generated SKILL.md frontmatter and write path both use the confirmed name.

### Write Path (SKILL-05)
- **D-09:** Write to `$USERPROFILE/.claude/skills/<name>/SKILL.md`. Use Bash to `mkdir -p` the directory first, then Write the file. `$USERPROFILE` not `~` (Windows requirement — D-06 from Phase 1).
- **D-10:** Confirm with user before writing — show full generated SKILL.md in a code block, then ask "Write it?" before any file operation.

### Claude's Discretion
- Adaptive threshold for how many questions to skip when argument is highly detailed — Claude applies judgment.
- Exact wording of AskUserQuestion option labels and descriptions (keep them short and concrete per the improve-prompt pattern).
- Whether to show the generated SKILL.md as a single fenced block or split by frontmatter + body.
- Standard empty-args guard output text (model the pattern from improve-prompt's guard).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Roadmap
- `.planning/REQUIREMENTS.md` — SKILL-01 through SKILL-05 define all Phase 3 acceptance criteria
- `.planning/ROADMAP.md` — Phase 3 success criteria (5 numbered items under Skill Creator Skill)
- `.planning/PROJECT.md` — Core constraints: skill format, Windows path requirement, AskUserQuestion 4-option limit, docs/ read-only at runtime

### Existing Skill (edit target)
- `skills/skill-create/SKILL.md` — Stub with correct frontmatter already set (`allowed-tools: [Read, Glob, Grep, Write, Bash]`, `disable-model-invocation: true`). Phase 3 replaces placeholder comment block with working instruction body. Do NOT change frontmatter fields.

### Reference Docs (runtime inputs to the skill)
- `skills/skill-create/references/extend-claude-with-skills.md` — Core: skill anatomy, frontmatter fields, invocation control, dynamic context injection. Always read first.
- `skills/skill-create/references/automate-workflows-with-hooks.md` — Read only when user's skill needs hook-based automation.
- `skills/skill-create/references/create-custom-subagents.md` — Read only when user's skill needs subagent dispatch.
- `skills/skill-create/references/run-claude-code-programmatically.md` — Read only when user's skill needs programmatic API calls.

### Pattern Reference
- `skills/improve-prompt/SKILL.md` — Complete working skill body. Use as the structural pattern: when-to-act guard, how-to-do section, output format, worked examples, final checks.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `skills/skill-create/SKILL.md` stub — frontmatter is final. Phase 3 writes the body only.
- `skills/skill-create/references/` — 4 reference files already present and comprehensive. No additional doc setup needed for Phase 3.
- `skills/improve-prompt/SKILL.md` — Full skill body pattern: guard → reasoning → output format → worked example → final checks. Mirror this structure.

### Established Patterns
- `$ARGUMENTS` substitution: already in stub. Skill body reads `$ARGUMENTS` as freeform description.
- Empty-args guard from improve-prompt: if `$ARGUMENTS` empty/whitespace → output usage message and stop. Apply same pattern in skill-create.
- YAML frontmatter `allowed-tools` already includes `[Read, Glob, Grep, Write, Bash]` — all tools needed for reading refs, writing skill file, and creating directory.
- `disable-model-invocation: true` already set on skill-create — user-invoked slash command only.

### Integration Points
- Generated skill lands at `$USERPROFILE/.claude/skills/<name>/SKILL.md`. Requires `Bash(mkdir -p)` + `Write`. Both are in `allowed-tools`.
- `settings.local.json.example` from Phase 1 already includes `Write(~/.claude/**)` and `Bash(mkdir:**)` — users who copied it have the required permissions.
- No integration with improve-prompt or workspace-create — skill-create is standalone.

</code_context>

<specifics>
## Specific Ideas

- Name proposal phrasing: `"I'd name this \`skill-name\` — change it?"` before any interview question.
- Selective ref loading decision point: after interview reveals tool/capability needs, load only the matching ref files before generating.
- Validation on write: confirm name is kebab-case, no `/`, `..`, or `\` chars before executing mkdir/Write.

</specifics>

<deferred>
## Deferred Ideas

- `docs/` topic files are now superseded by `references/` — `docs/index.md` may need an update to reflect this. Deferred to Phase 4 or a cleanup task; doesn't affect Phase 3 output.
- Preview/edit loop depth (how many iterations allowed before write) — not discussed. Claude applies the same confirm-before-write pattern as improve-prompt.

</deferred>

---

*Phase: 3-Skill Creator Skill*
*Context gathered: 2026-04-27*
