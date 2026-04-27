# Phase 3: Skill Creator Skill - Research

**Researched:** 2026-04-27
**Domain:** Claude Code skill authoring — SKILL.md body writing for a skill-generating skill
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Adaptive pacing — Claude reads `$ARGUMENTS` first, infers what it can, asks only about genuinely ambiguous aspects. Clear requests get fewer questions; vague descriptions get more (up to 5-6 total including name confirmation).
- **D-02:** Proposed answers use AskUserQuestion options (2-3 concrete labels + descriptions per question). "Other" auto-provided for freeform. 4-option hard limit applies — never design a question bank that exceeds 3 explicit options.
- **D-03:** Four required interview topics — always cover regardless of argument clarity:
  1. **Trigger pattern** — auto-invoked by Claude vs. user-only (`disable-model-invocation: true`). Propose right default.
  2. **Tools needed** — shapes `allowed-tools` frontmatter. Propose based on description.
  3. **Output destination** — chat only, file write, or both. Determines if Write/Bash are needed.
  4. **Edge cases / guards** — empty `$ARGUMENTS`, bad input, missing context. Propose standard guard pattern as default.
- **D-04:** Read from `references/` dir only — 4 pre-loaded files in `skills/skill-create/references/`. Supersedes literal `${CLAUDE_SKILL_DIR}/docs/` in SKILL-02.
- **D-05:** Selective reading — always read `extend-claude-with-skills.md` first; read the other 3 only when interview reveals user's skill needs hooks, subagents, or programmatic API.
- **D-06:** Read before interview — reference docs loaded before the first interview question.
- **D-07:** Claude infers kebab-case name from description, proposes it: `"I'd name this \`skill-name\` — change it?"`. Validate: kebab-case only, no `/`, `..`, `\`.
- **D-08:** Name confirmed before interview questions proceed — no rename at preview step.
- **D-09:** Write to `$USERPROFILE/.claude/skills/<name>/SKILL.md`. Use Bash `mkdir -p`, then Write. `$USERPROFILE` not `~`.
- **D-10:** Confirm with user before writing — show full generated SKILL.md in a code block, then ask "Write it?" before any file operation.

### Claude's Discretion

- Adaptive threshold for how many questions to skip when argument is highly detailed.
- Exact wording of AskUserQuestion option labels and descriptions (keep short and concrete).
- Whether to show generated SKILL.md as single fenced block or split by frontmatter + body.
- Standard empty-args guard output text (model after improve-prompt's guard).
- Preview/edit loop iteration depth before write.

### Deferred Ideas (OUT OF SCOPE)

- `docs/index.md` update to reflect that `references/` supersedes download instructions — deferred to Phase 4 or cleanup.
- Preview/edit loop depth (how many iterations) — Claude applies same confirm-before-write pattern as improve-prompt.

</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SKILL-01 | User can invoke `/skill-create` and describe the skill they want to build (freeform or via argument) | Empty-args guard + `$ARGUMENTS` ingestion pattern; name inference and confirmation flow |
| SKILL-02 | Skill reads `${CLAUDE_SKILL_DIR}/docs/` before generating (satisfied by `references/` per D-04) | `${CLAUDE_SKILL_DIR}` substitution variable; selective read protocol D-05/D-06 |
| SKILL-03 | Skill interviews user with 5-6 targeted questions, each offering proposed answers | AskUserQuestion ≤3 explicit options pattern; D-02 and D-03 four-topic bank |
| SKILL-04 | Generated SKILL.md shown for review and confirmation before any file write | D-10 chat preview in 4-backtick fence + "Write it?" gate |
| SKILL-05 | Confirmed skill written to `~/.claude/skills/<name>/SKILL.md` (global scope) | D-09 `$USERPROFILE` path; `mkdir -p` + Write sequence; kebab-case + path-traversal validation |

</phase_requirements>

---

## Summary

Phase 3 writes the instruction body of `skills/skill-create/SKILL.md`. The stub already has correct, final frontmatter (`allowed-tools: [Read, Glob, Grep, Write, Bash]`, `disable-model-invocation: true`). The executor replaces the placeholder comment block with a working Markdown body — no frontmatter changes.

The skill is a skill-authoring skill: it reads its own reference docs, interviews the user via AskUserQuestion, generates a new SKILL.md, shows it for confirmation, then writes it globally. The body structure follows the same recipe as `improve-prompt/SKILL.md` (guard → how-to sections → worked examples → final checks), adapted for an interactive multi-step workflow.

The dominant technical risks are: (1) fence-nesting when previewing the generated SKILL.md in chat, (2) AskUserQuestion option count exceeding 4, (3) Windows path resolution using `~` instead of `$USERPROFILE`, and (4) omitting `mkdir -p` before the Write call.

**Primary recommendation:** Write the body as a linear sequence of numbered stages (guard, read-refs, name, interview, generate, preview, confirm, write) with each stage's constraints stated explicitly. Provide a worked example tracing a concrete invocation end-to-end.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Skill body authoring | SKILL.md content (executed inline by Claude) | — | Entire skill runs inline; no subagent, no fork. `disable-model-invocation: true` means no ambient context injection. |

---

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| SKILL.md body | Markdown | Instruction content Claude executes | Required by skills platform |
| YAML frontmatter | Already final in stub | Invocation config (`allowed-tools`, `disable-model-invocation`) | Platform-required; do not modify |
| `$ARGUMENTS` substitution | Built-in | Receives freeform skill description from user | Only input channel for user text |
| `${CLAUDE_SKILL_DIR}` substitution | Built-in | Resolves path to `references/` dir at runtime | Required for path-portable Read calls |
| AskUserQuestion tool | Built-in | Interview questions with constrained option sets | Only interactive input mechanism |
| Read tool | In `allowed-tools` | Loads reference docs before interview | D-06 pre-interview read |
| Write tool | In `allowed-tools` | Writes generated SKILL.md to global path | D-09 file output |
| Bash tool | In `allowed-tools` | `mkdir -p` before Write; `$USERPROFILE` resolution | Required — Write fails without parent dir |

**No npm packages. No external libraries. No network calls.**
[VERIFIED: CONTEXT.md D-04, frontmatter stub read above]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `${CLAUDE_SKILL_DIR}/references/` | Hardcoded path | Hardcoded paths break when plugin is installed at a different location — always use `${CLAUDE_SKILL_DIR}` |
| `$USERPROFILE` Bash resolution | `~` expansion | `~` is not reliably expanded by the Write tool on Windows (confirmed Issue #30553) — always resolve via Bash first |
| 4-backtick outer fence for preview | Triple-backtick | Generated SKILL.md body contains triple-backtick fences; triple wrapping breaks parsing |

---

## Architecture Patterns

### System Architecture Diagram

```
User invokes /skill-create [description]
        |
        v
[1] Empty-args guard
    $ARGUMENTS empty? --> Output usage message, STOP
        |
        v
[2] Read references/extend-claude-with-skills.md
    (always -- before first question)
        |
        v
[3] Infer kebab-case name from $ARGUMENTS
    Propose: "I'd name this `skill-name` -- change it?"
    AskUserQuestion: "Yes, use this name" / "Enter a different name"
        |
        v (name confirmed -- no further rename)
[4] Adaptive interview (D-03 four topics, <=3 explicit options each)
    Q: Trigger pattern   --> disable-model-invocation?
    Q: Tools needed      --> allowed-tools list
    Q: Output dest       --> chat / file write / both
    Q: Edge cases/guards --> empty args guard style
    (Skip questions where $ARGUMENTS already answers them)
        |
        v
[5] Conditional ref reads (D-05)
    hooks needed?       --> read automate-workflows-with-hooks.md
    subagents needed?   --> read create-custom-subagents.md
    programmatic API?   --> read run-claude-code-programmatically.md
        |
        v
[6] Generate SKILL.md content in memory
    frontmatter (name, description, allowed-tools, disable-model-invocation)
    + instruction body grounded in reference docs
        |
        v
[7] Preview -- show full SKILL.md in 4-backtick fence
    Ask in chat: "Write it?" (no AskUserQuestion here -- D-10)
        |
        v
[8] Validate name: ^[a-z0-9]+(-[a-z0-9]+)*$ -- reject /, .., \
    Bash: SKILL_DIR="$USERPROFILE/.claude/skills/<name>"
          mkdir -p "$SKILL_DIR"
    Write: "$SKILL_DIR/SKILL.md" with generated content
        |
        v
[9] Confirm write in chat: "Written to $USERPROFILE/.claude/skills/<name>/SKILL.md"
```

### Recommended File Structure

The skill body lives entirely in `skills/skill-create/SKILL.md`. No new files are created in the repo by Phase 3. Generated skills land at the user's global path.

```
skills/skill-create/
├── SKILL.md              # Phase 3 writes the instruction body here
└── references/
    ├── extend-claude-with-skills.md    # Always read (D-05)
    ├── automate-workflows-with-hooks.md
    ├── create-custom-subagents.md
    └── run-claude-code-programmatically.md
```

### Pattern 1: Empty-args Guard (from improve-prompt)

**What:** First thing in the body — check `$ARGUMENTS` and stop cleanly if empty.
**When to use:** Every skill that requires user input as `$ARGUMENTS`.

```markdown
<!-- Source: skills/improve-prompt/SKILL.md, line 14-19 -->
## When to act

If `$ARGUMENTS` is empty or contains only whitespace, output exactly:

> Provide a description of the skill you want to create, for example:
> `/skill-create a slash command that summarizes git logs`

Then stop — do not attempt an interview, do not ask a clarifying question.
```

[VERIFIED: improve-prompt/SKILL.md read above]

### Pattern 2: AskUserQuestion with ≤3 Explicit Options

**What:** Each interview question uses AskUserQuestion with exactly 2-3 concrete labeled options. The platform appends "Other" automatically, bringing the total to 3-4 (never over 4).
**When to use:** All 4 interview topics (D-03) and the name confirmation step (Stage 3).

```markdown
<!-- Illustrative shape -- exact labels are Claude's Discretion -->
## Interview step: Trigger pattern

Use AskUserQuestion:
  Question: "Should Claude invoke this skill automatically, or only when you type /name?"
  Options (<=3 explicit):
    - "User-only slash command" -- Add disable-model-invocation: true. Best for side-effectful workflows.
    - "Claude auto-invokes" -- No restriction. Best for reference/knowledge skills.
    - "Propose based on description" -- Claude decides from context (selects one of the above).
```

**Constraint:** Total options including auto-"Other" = 4 maximum. Design every question with ≤3 explicit options.
[VERIFIED: CONTEXT.md D-02, CLAUDE.md key constraints, STATE.md decisions]

### Pattern 3: Windows Write Path

**What:** Resolve `$USERPROFILE` via Bash, then use that in Write. Never pass `~` to Write.
**When to use:** D-09 — the skill's final write step.

```bash
# Source: CONTEXT.md D-09, confirmed by STATE.md note on Issue #30553
# $USERPROFILE is exported as an env var in git-bash on Windows -- use it directly
SKILL_DIR="$USERPROFILE/.claude/skills/<validated-name>"
mkdir -p "$SKILL_DIR"
# Then: Write tool writes to "$SKILL_DIR/SKILL.md"
```

Note: `$USERPROFILE` is exported by git-bash on Windows and is the correct env var. Never use `~` in a Write path — tilde expansion is shell-only and the Write tool receives the literal string.
[VERIFIED: CONTEXT.md D-09, CLAUDE.md key constraints, STATE.md decisions]

### Pattern 4: 4-backtick Fence for SKILL.md Preview

**What:** Wrap the generated SKILL.md preview in a 4-backtick outer fence so inner triple-backtick fences (YAML frontmatter example, code blocks in the body) parse correctly.
**When to use:** D-10 preview step.

```markdown
<!-- Instruction to Claude in the skill body -->
Display the generated SKILL.md inside a 4-backtick fenced block:

````markdown
---
name: [name]
...
---

[body]
````
```

[VERIFIED: improve-prompt/SKILL.md worked examples section; STATE.md Pitfall 1 decision]

### Pattern 5: Instruction Body Structure (from improve-prompt)

The improve-prompt body teaches the correct prose structure for skill bodies:

1. `## When to act` — guard condition (imperative, stops immediately if not met)
2. `## How to [do the thing]` — numbered steps, not bullets; concrete actions
3. `## [Subsection per major decision]` — each interview topic gets its own section
4. Worked example — 4-backtick outer fence; traces a concrete invocation start-to-finish
5. `## Final checks before responding` — numbered checklist Claude verifies before acting

All instructions written in second person to Claude (imperative: "Read", "Propose", "Ask", "Write").
[VERIFIED: improve-prompt/SKILL.md read above]

### Anti-Patterns to Avoid

- **4 explicit options in AskUserQuestion:** The platform auto-appends "Other" — 4 explicit + auto-Other = 5 total, which breaks the hard limit. Keep explicit options at ≤3.
- **Using `~` in Write path on Windows:** Write tool does not expand `~` reliably on Windows. Always resolve via `$USERPROFILE`.
- **Write before mkdir -p:** Write fails silently or errors if parent directory does not exist. Always `mkdir -p` first.
- **Renaming at the preview/confirm step:** D-08 locks the name before the interview begins. If the preview shows the wrong name, the skill body has a logic error. Don't design a rename escape hatch at D-10.
- **AskUserQuestion for the "Write it?" confirmation (D-10):** A chat-level "Write it?" prompt is correct. AskUserQuestion after a long interview adds friction; the user can just reply "yes" in chat.
- **Running interview before reading refs (violates D-06):** Proposed options in AskUserQuestion must be grounded in actual frontmatter field names. Read `extend-claude-with-skills.md` first.
- **Hardcoding `skills/skill-create/references/` path:** Use `${CLAUDE_SKILL_DIR}/references/` — the substitution resolves correctly regardless of install location.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Kebab-case name validation | Custom character-by-character loop | `^[a-z0-9]+(-[a-z0-9]+)*$` regex check in Bash | Single-expression; handles edge cases (leading hyphens, consecutive hyphens, uppercase) |
| Directory creation before write | Existence check + conditional mkdir | `mkdir -p` unconditionally | Idempotent; handles nested paths; no race condition |
| Path traversal detection | Manual string scanning | Combined: reject if name contains `/`, `..`, or `\` + regex validation | Belt-and-suspenders; regex alone doesn't catch all traversal forms |
| YAML frontmatter construction | String concatenation by hand | Template section in skill body with explicit field order | Avoids escaping bugs; maintains consistent frontmatter structure |

**Key insight:** The planner's tasks are primarily prose authoring; hand-rolled logic only appears in the write step (Bash path resolution + validation). Keep it minimal.

---

## Common Pitfalls

### Pitfall 1: Fence Nesting in SKILL.md Preview

**What goes wrong:** The generated SKILL.md contains YAML frontmatter (wrapped in `---`) and code examples (wrapped in triple-backtick fences). If the preview wraps them in a triple-backtick fence, the first triple-backtick code block inside the generated content terminates the outer fence — the preview renders broken.

**Why it happens:** The improve-prompt skill hit this same issue when encoding its own worked examples. The fix used there (4-backtick outer fence) is the standard pattern.

**How to avoid:** Instruct Claude in the skill body to wrap the SKILL.md preview in a 4-backtick (`` ```` ``) outer fence.

**Warning signs:** Preview appears cut off at the first `` ``` `` inside the generated content.

[VERIFIED: improve-prompt/SKILL.md lines 62-105; STATE.md Pitfall 1 decision]

---

### Pitfall 2: AskUserQuestion Option Count Overflow

**What goes wrong:** Designer writes a question with 4 explicit options thinking they fill the 4-option limit. The platform auto-appends "Other" as option 5. Result: undefined behavior or error.

**Why it happens:** The 4-option limit is total options including auto-"Other" — not explicit-options-only.

**How to avoid:** Design every question bank with ≤3 explicit options. State this in the skill body as an inline reminder: "each AskUserQuestion call uses ≤3 explicit options (platform adds 'Other' automatically)."

**Warning signs:** Question with 4 explicit choices in the skill body — flag immediately.

[VERIFIED: CLAUDE.md key constraints, CONTEXT.md D-02, STATE.md decisions]

---

### Pitfall 3: `~` on Windows Write Path

**What goes wrong:** Write tool receives `~/.claude/skills/...` on Windows. `~` is not expanded by the Write tool; the literal `~` character appears in the file path, creating a directory named `~` in the current working directory.

**Why it happens:** Tilde expansion is a shell feature; tools receive the literal string unless expansion happens in Bash first.

**How to avoid:** Always resolve the path in Bash (using `$USERPROFILE`), capture the result, then pass the resolved absolute path to Write.

**Warning signs:** Skill body uses `~` directly in a Write call without a preceding Bash resolution step.

[VERIFIED: CONTEXT.md D-09, STATE.md decision on Issue #30553]

---

### Pitfall 4: Write Without mkdir -p

**What goes wrong:** Write fails because `$USERPROFILE/.claude/skills/<name>/` does not exist. The skill directory is created per skill-name at write time — it never pre-exists.

**Why it happens:** Write does not create parent directories.

**How to avoid:** Bash `mkdir -p "$SKILL_DIR"` immediately before the Write call in the skill body's write stage.

**Warning signs:** Write call with no preceding mkdir step in the same stage.

[VERIFIED: skills platform behavior; CONTEXT.md D-09 explicitly specifies this sequence]

---

### Pitfall 5: Name Validation After mkdir (Too Late)

**What goes wrong:** Name passes a weak check, `mkdir -p` runs, then validation catches a bad character — but the directory was already created at the invalid path.

**Why it happens:** Validation placed after side effects.

**How to avoid:** Validate the name (regex + traversal chars) before the Bash step. Structure: validate → mkdir -p → Write.

**Warning signs:** mkdir before name validation in the write stage.

---

### Pitfall 6: Interview Before Reading References

**What goes wrong:** AskUserQuestion options reference frontmatter fields (e.g., `disable-model-invocation`, `allowed-tools`, `context: fork`) that Claude hasn't verified from docs yet. Generated options may use wrong field names or omit valid options.

**Why it happens:** Reading feels optional when training knowledge covers the material. But D-06 is a locked decision, and training data may be stale.

**How to avoid:** Instruct Read of `${CLAUDE_SKILL_DIR}/references/extend-claude-with-skills.md` explicitly as Stage 2 (before any AskUserQuestion). The skill body must make this a numbered step, not an implicit behavior.

**Warning signs:** AskUserQuestion calls appearing in the body before any Read call.

---

## Code Examples

### Kebab-Case Validation in Bash

```bash
# Source: CONTEXT.md D-07 + standard bash regex
NAME="$1"
if [[ ! "$NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || [[ "$NAME" == *".."* ]] || [[ "$NAME" == *"/"* ]] || [[ "$NAME" == *"\\"* ]]; then
  echo "Invalid skill name: must be lowercase letters, numbers, and hyphens only."
  exit 1
fi
```

[ASSUMED — exact bash syntax; intent verified from CONTEXT.md D-07]

### mkdir + Write Sequence

```bash
# Resolve USERPROFILE (works in git-bash on Windows; $USERPROFILE is exported by the shell)
SKILL_DIR="$USERPROFILE/.claude/skills/$NAME"
mkdir -p "$SKILL_DIR"
# Then: Write tool writes to "$SKILL_DIR/SKILL.md"
```

[VERIFIED: CONTEXT.md D-09]

### SKILL.md Frontmatter Template Shape

```yaml
---
name: <kebab-case-name>
description: "<what it does and when to use it — front-load the key use case>"
argument-hint: [<hint>]
allowed-tools: [<tools-from-interview>]
disable-model-invocation: <true|false from interview>
---
```

[VERIFIED: extend-claude-with-skills.md frontmatter reference table, lines 186-216]

### ${CLAUDE_SKILL_DIR} Read Call Shape

```markdown
<!-- In skill body -- Read call using platform substitution -->
Read `${CLAUDE_SKILL_DIR}/references/extend-claude-with-skills.md` to ground your understanding
of frontmatter fields, invocation control, and AskUserQuestion constraints before asking anything.
```

[VERIFIED: extend-claude-with-skills.md — `${CLAUDE_SKILL_DIR}` substitution table, line 229]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.claude/commands/*.md` flat files | `skills/<name>/SKILL.md` with frontmatter | Claude Code skills platform | Skills support supporting files, frontmatter control, subagent context |
| `~` for global skills path | `$USERPROFILE` on Windows | v2.1.79+ permission regression | `~` unreliable in Write tool on Windows |
| Unrestricted Write permission | `settings.local.json` allow-list required | v2.1.79+ (Issue #36497) | Users must add `Write(~/.claude/**)` allow entry |

[VERIFIED: CONTEXT.md, STATE.md, PROJECT.md, extend-claude-with-skills.md]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact bash regex `^[a-z0-9]+(-[a-z0-9]+)*$` is sufficient for kebab-case validation | Code Examples | Could allow edge-case invalid names; executor should verify against Claude Code name field spec in extend-claude-with-skills.md (max 64 chars, lowercase letters/numbers/hyphens) |
| A2 | `$USERPROFILE` is reliably set in git-bash environment on Windows | Code Examples | On non-standard installs, may be unset; executor should add fallback to `$HOME` |
| A3 | AskUserQuestion auto-appends exactly one "Other" option (total = explicit + 1) | Architecture Patterns, Pitfalls | If auto-Other behavior changed, constraint is off; CLAUDE.md SKILL.md constraint confirms 4-option hard limit |

**All other claims were verified or cited from read files in this session.**

---

## Open Questions (RESOLVED)

1. **Conditional reference reads: how does Claude decide which to load?**
   RESOLVED: Planner specified decision rules in Stage 5 of 03-01-PLAN.md:
   - hooks ref: Topic 1 selects hook-based trigger OR Topic 2 includes Bash hook operations
   - subagents ref: Topic 3 selects subagent/fork output destination
   - programmatic ref: description or interview answers mention CI, scripts, or programmatic invocation

---

## Environment Availability

Step 2.6: No external dependencies identified beyond Bash (mkdir) and Write — both are in the stub's `allowed-tools`. No audit needed.

The one environment prerequisite is the user having `Write(~/.claude/**)` and `Bash(mkdir:**)` in their `settings.local.json` allow list. This was addressed in Phase 1 (SETUP-05). Document in the skill body that users without these permissions will see a permission prompt on first write.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Structural grep (bash) + manual UAT — no automated test runner for skill bodies |
| Config file | None — following Phase 2 pattern |
| Quick run command | `grep -c "When to act" skills/skill-create/SKILL.md` (structural check) |
| Full suite command | Manual invocation: `/skill-create a skill that summarizes git logs` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SKILL-01 | Empty-args guard present and halts | structural-grep | `grep -c "empty or contains only whitespace" skills/skill-create/SKILL.md` | Wave 0 |
| SKILL-01 | `$ARGUMENTS` ingestion present | structural-grep | `grep -c "ARGUMENTS" skills/skill-create/SKILL.md` | Wave 0 |
| SKILL-02 | Read `${CLAUDE_SKILL_DIR}/references/` instruction present | structural-grep | `grep -c "CLAUDE_SKILL_DIR" skills/skill-create/SKILL.md` | Wave 0 |
| SKILL-03 | AskUserQuestion usage instruction present | structural-grep | `grep -c "AskUserQuestion" skills/skill-create/SKILL.md` | Wave 0 |
| SKILL-03 | Four interview topics all present (trigger, tools, output, guards) | structural-grep | `grep -cE "trigger\|disable-model-invocation\|allowed-tools\|output dest\|guard" skills/skill-create/SKILL.md` | Wave 0 |
| SKILL-04 | Preview step present (4-backtick fence instruction) | structural-grep | `grep -c "Write it" skills/skill-create/SKILL.md` | Wave 0 |
| SKILL-05 | `$USERPROFILE` write path present | structural-grep | `grep -c "USERPROFILE" skills/skill-create/SKILL.md` | Wave 0 |
| SKILL-05 | `mkdir -p` instruction present | structural-grep | `grep -c "mkdir" skills/skill-create/SKILL.md` | Wave 0 |
| ALL | End-to-end skill creation flow works | manual-UAT | `/skill-create a skill that summarizes git log output` | Manual |

### Sampling Rate

- **Per task commit:** Run one structural grep from the table above for the task's requirement
- **Per wave merge:** All structural grep checks pass (full table above)
- **Phase gate:** All structural checks green + manual UAT approved before `/gsd-verify-work`

### Wave 0 Gaps

- All structural grep commands run against `skills/skill-create/SKILL.md` — the file exists (stub). Tests pass when the body is written. No new test files needed; grep runs inline.
- Manual UAT: user invokes `/skill-create` in a live Claude Code session after body is written.

---

## Security Domain

`security_enforcement` not explicitly set to `false` in config. Including required section.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Not applicable — local file write, no auth |
| V3 Session Management | No | Not applicable — stateless skill invocation |
| V4 Access Control | Partial | Write permission gated by `settings.local.json` allow-list |
| V5 Input Validation | Yes | Kebab-case regex + path traversal rejection on skill name from interview |
| V6 Cryptography | No | No secrets, no encryption needed |

### Known Threat Patterns for Skill Body

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via skill name | Tampering | Reject names containing `/`, `..`, `\` before mkdir/Write |
| Unvalidated name written to global path | Tampering | Regex `^[a-z0-9]+(-[a-z0-9]+)*$` gates all writes |
| Overwrite existing skill without warning | Tampering | Preview step (D-10) shows target path; user confirms before write. Note: no existence check designed — planner should decide if a "skill already exists" warning is needed. |

**Note on overwrite warning:** CONTEXT.md and the discussion log do not specify behavior when a skill at the target path already exists. The planner should decide: either warn the user ("skill `name` already exists — overwrite?") or silently overwrite. Recommend warning as the safer default.

---

## Sources

### Primary (HIGH confidence)
- `skills/skill-create/SKILL.md` stub — frontmatter fields confirmed final
- `skills/improve-prompt/SKILL.md` — structural pattern: guard, sections, worked examples, final checks
- `skills/skill-create/references/extend-claude-with-skills.md` — frontmatter fields, `${CLAUDE_SKILL_DIR}` substitution, AskUserQuestion, `allowed-tools`, `disable-model-invocation`, `$ARGUMENTS`
- `.planning/phases/03-skill-creator-skill/03-CONTEXT.md` — all locked decisions D-01 through D-10
- `.planning/phases/03-skill-creator-skill/03-DISCUSSION-LOG.md` — decision rationale
- `./CLAUDE.md` (project) — AskUserQuestion 4-option limit, Windows path requirement, `disable-model-invocation` constraint

### Secondary (MEDIUM confidence)
- `.planning/STATE.md` — confirmed Issue #30553 (Windows `~` path), Issue #36497 (permission regression), Pitfall 1 (4-backtick fence), Pitfall 2 (empty-args guard)
- `.planning/PROJECT.md` — project constraints cross-referenced

### Tertiary (LOW confidence)
- None — all material sourced from local codebase files read this session.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no external libraries; all tools from existing stub; verified from read files
- Architecture: HIGH — all decisions locked in CONTEXT.md; improve-prompt pattern verified from read file
- Pitfalls: HIGH — most sourced from STATE.md accumulated decisions (team already encountered them)
- Validation: HIGH — same structural-grep + manual-UAT pattern used successfully in Phase 2

**Research date:** 2026-04-27
**Valid until:** Stable — skill authoring patterns change only with Claude Code platform releases. No expiry concern within Phase 3 timeline.
