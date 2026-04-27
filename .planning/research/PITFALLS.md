# Pitfalls Research

**Domain:** Claude Code skill development (slash-command plugins)
**Researched:** 2026-04-26
**Confidence:** HIGH for permission/path issues (primary sources from GitHub issues); MEDIUM for AskUserQuestion limits (confirmed by issue #12420); MEDIUM for instruction-clarity patterns (multiple community sources); LOW for exact header character limits in AskUserQuestion (not found in official docs)

---

## Critical Pitfalls

### Pitfall 1: Writing Skills to Wrong Location — Project vs. Global Scope

**What goes wrong:**
When Claude Code writes a skill file during the skill-creator skill, it defaults to the project-level `.claude/skills/` directory rather than the user-level `~/.claude/skills/` directory. The generated skill is scoped to the current project only and is invisible in all other sessions — the opposite of the stated requirement.

**Why it happens:**
Claude Code's skill-writing logic defaults to the nearest `.claude/` ancestor — which is the project directory. Nothing in the UX distinguishes the two scopes. The skill-creator skill prompt must explicitly instruct writing to `~/.claude/skills/<name>/SKILL.md`. This is a documented bug (Issue #16165, closed as "not planned") where skills behave inconsistently with agents — agents correctly create both user-level and project-level resources; skills only create at project-level without explicit instruction.

**How to avoid:**
The skill-creator skill must hardcode the target path as `~/.claude/skills/<skill-name>/SKILL.md`. Use a Bash tool call to resolve the actual home directory before writing: `echo "$HOME"` on Unix/macOS, `echo "$USERPROFILE"` on Windows native. Never rely on Claude's default file-write behavior to land in the correct scope. Confirm the path with the user before writing.

**Warning signs:**
- Generated skill appears only when running Claude Code from the project directory
- `/help` or skill list shows the new skill, but it vanishes in other project sessions
- The write goes to `.claude/skills/` (relative) rather than `~/.claude/skills/` (absolute home-anchored)

**Phase to address:** Skill creator skill (Phase 2). Write the target path explicitly into the skill-creator instructions as a non-negotiable constant, not a runtime decision.

---

### Pitfall 2: Permission Prompt Blocks Skill Writing — Regression in v2.1.79+

**What goes wrong:**
Writing to `.claude/skills/` (and by extension `~/.claude/skills/`) triggers an interactive permission prompt in Claude Code v2.1.79+ even though the documentation explicitly states `.claude/skills/` is exempt from the `.claude/` directory protection. The skill-creator skill stalls waiting for user confirmation every time it tries to save a generated skill file.

**Why it happens:**
A regression introduced in v2.1.79 extended `.claude/` path protection to include skills directories. The source code exemption list only includes `.claude/commands` and `.claude/agents` — `.claude/skills` is missing despite documentation claiming otherwise (Issue #36497, open). The documentation and the running binary are out of sync.

**How to avoid:**
Add the following to `settings.local.json` in any project that uses the skill-creator:
```json
{
  "permissions": {
    "allow": ["Write(.claude/**)", "Edit(.claude/**)", "Write(~/.claude/**)", "Edit(~/.claude/**)"]
  }
}
```
Include explicit permission setup instructions in the skill-creator skill body so Claude can prompt the user to configure this before the first skill-write attempt. Treat this as a known bug that may be fixed in a future version — check the Claude Code changelog at each version update.

**Warning signs:**
- Claude pauses mid-skill-creation asking "may I write to .claude/skills/…?"
- Skill creation succeeds in one session but prompts repeatedly in subsequent ones
- Error logs reference permission denial for `.claude/` subdirectory writes

**Phase to address:** Skill creator skill (Phase 2). Include permission pre-flight check in the skill-creator instructions. Document the `settings.local.json` fix in the skill-creator skill itself.

---

### Pitfall 3: Windows Path Separator Breaks Generated File Paths

**What goes wrong:**
Skills that generate file paths (the workspace creator producing `.workspace/`, `.claude/`, `.vscode/` paths; the skill creator writing to `~/.claude/skills/`) produce Unix-style forward-slash paths by default. On Windows native Claude Code, file-write tools require Windows-native backslash paths — the tools fail silently or create files at wrong locations.

**Why it happens:**
Claude Code runs on Windows native (without WSL) as of 2026, but Claude's internal path-generation defaults to Unix conventions. The shell context (Git Bash) displays POSIX paths even on Windows. The mismatch between shell-display paths and file-tool paths causes writes to fail or land in unexpected locations. This is a confirmed issue (GitHub Issue #30553, closed as "not planned") — Anthropic has no plans to automatically adapt path format.

**How to avoid:**
Detect the platform at the start of each skill using a Bash tool call:
```bash
uname -o 2>/dev/null || echo "windows"
```
Or check `$OS` environment variable (`Windows_NT` on Windows). Then branch path construction accordingly. For the workspace creator: generate all paths using forward slashes in the skill instructions (Claude Code's Write/Read tools on Windows accept forward slashes as of recent versions), but avoid relying on tilde (`~`) expansion for global paths — resolve to the absolute home path first. Also add `# Windows 11 — use Windows-compatible paths` to the project's CLAUDE.md as a safety net, since users on this machine may not have this globally.

**Warning signs:**
- File writes fail with "path not found" errors despite the parent directory existing
- Directories appear with `\` in their display name (escaped backslash treated as literal)
- The workspace creator creates `.workspace\refs\` as a file instead of a nested directory

**Phase to address:** Workspace creator skill (Phase 3) and skill creator skill (Phase 2). Both generate file paths. Add explicit platform-detection logic and path construction instructions to both skills.

---

### Pitfall 4: Skill Description Is Too Vague — Autonomous Activation Never Fires

**What goes wrong:**
A skill with a generic description like `"Use this skill to improve prompts"` never activates autonomously. Claude either ignores it entirely or activates it on unrelated requests. Real-world data shows baseline skill activation rates around 20% (coin-flip) with vague descriptions alone.

**Why it happens:**
Claude Code uses the `description` field in the SKILL.md frontmatter as the sole routing signal for autonomous activation. Vague descriptions give Claude no concrete pattern to match against. Additionally, the description must use third-person phrasing ("This skill should be used when…") to be parsed correctly by the skill router. Missing or too-short descriptions (<50 characters) are caught as errors by diagnostic tools — 14 of 23 community-audited skills had structural description issues.

**How to avoid:**
Write skill descriptions in third-person with explicit trigger phrases in quotes:
```yaml
description: This skill should be used when the user asks to "improve this prompt", "rewrite this prompt", "make this prompt clearer", or provides a rough prompt and asks Claude to refine it. Do NOT use for general writing improvements unrelated to Claude prompts.
```
Include a "Do NOT use for…" clause — this is as important as the trigger phrases because it prevents false positives that hijack unrelated conversations. Keep the description between 50 and 500 characters.

**Warning signs:**
- Invoking the skill by name works, but it never fires automatically on natural language requests
- The skill fires on unrelated requests (over-broad description)
- Typos in the description field cause intermittent activation (30% instead of expected 80%+)

**Phase to address:** All three skills (Phases 1–3). Every SKILL.md needs this treatment. Review the description during skill-creator skill output validation before saving.

---

### Pitfall 5: AskUserQuestion Hard Limit of 4 Options Per Question

**What goes wrong:**
Any AskUserQuestion call with more than 4 options per question throws an `InputValidationError` and aborts the interview flow entirely. The workspace creator (which needs to ask about repos to include, workspace purpose, naming conventions) and the skill creator (which interviews the user about skill requirements) both risk hitting this if they present lists of choices naively.

**Why it happens:**
AskUserQuestion has a schema-enforced maximum: `"Array must contain at most 4 element(s)"` for the `options` array. This is a deliberate design constraint (Issue #12420), not a bug — Anthropic considers 4 options sufficient for structured choice. The tool is not designed for dynamic menu selection from arbitrary-length lists.

**How to avoid:**
- Never present more than 4 options in a single AskUserQuestion call
- For "pick from a list" scenarios (e.g., which repos to include): use a text-input question instead of a choice question, or break into multiple sequential calls ("Which of these first four? [A/B/C/D]… Any others?")
- Use `multiSelect: true` for questions where multiple answers are valid, rather than stacking multiple single-choice questions
- For the workspace creator skill: ask open-ended text questions for repo names and purpose; reserve choices for binary/small-set decisions (e.g., "Include .vscode/? [Yes/No]")
- Design the interview to require no more than 5-7 total questions; more than this causes user fatigue without adding quality

**Warning signs:**
- Interview crashes midway through with an InputValidationError
- Claude silently falls back to plain-text numbered lists instead of the interactive choice UI
- The skill produces partial output because the interview was aborted

**Phase to address:** Workspace creator skill (Phase 3) and skill creator skill (Phase 2). Both have multi-question interview flows. Design question banks with ≤4 options each before writing the skill instructions.

---

### Pitfall 6: Generated CLAUDE.md Is a Stub — Workspace Creator Fails Its Core Promise

**What goes wrong:**
The workspace creator skill generates a CLAUDE.md file with placeholder content ("Add your workspace purpose here", "List your repos here") rather than actual content derived from the interview answers. The user gets a template they must fill in manually — precisely the outcome the skill is supposed to prevent.

**Why it happens:**
Skill instructions that say "generate a CLAUDE.md" without specifying that content must come from the interview answers will produce stub output. Claude defaults to template-style output when the skill body doesn't explicitly constrain it to use collected answers. This is compounded by skills that interview the user and then start a new context to write the file — losing the interview answers in the process.

**How to avoid:**
The workspace creator skill instructions must:
1. Explicitly state "use the user's answers from the interview to populate every section — no stubs, no placeholders"
2. Include a template of the expected CLAUDE.md structure with markers showing which interview answer fills each section (e.g., "Purpose: {answer to Q1 about workspace goal}")
3. Perform the file write in the same turn as the interview — do not spawn a subagent for writing if that risks losing conversation context
4. Include a validation step: after writing, read the file back and confirm no lines contain "TODO", "placeholder", "[your", or similar stub patterns

**Warning signs:**
- Generated CLAUDE.md contains angle-bracket placeholders (`<your workspace name>`)
- Workspace purpose section is generic ("This workspace is for development work")
- Repos section is empty or contains example repo names instead of user-provided names

**Phase to address:** Workspace creator skill (Phase 3). This is the defining quality gate for that skill — it either produces real content or it doesn't.

---

### Pitfall 7: Skill File Nesting One Level Too Deep

**What goes wrong:**
A generated skill is saved to `~/.claude/skills/my-skill/subfolder/SKILL.md` instead of `~/.claude/skills/my-skill/SKILL.md`. Claude Code does not discover it. The skill creator appears to succeed (no error), but the skill never appears in the available skills list.

**Why it happens:**
The skill creator skill may generate a directory structure that looks organized (putting SKILL.md inside a named subfolder) but violates Claude Code's auto-discovery rules. The correct structure is exactly two levels deep: `skills/<skill-name>/SKILL.md`. Any additional nesting makes the skill invisible. This is the most frequent installation error reported in community sources.

**How to avoid:**
Hardcode the path pattern in the skill creator skill instructions as:
```
~/.claude/skills/{skill-name}/SKILL.md
```
Never generate a `{skill-name}/` subdirectory containing another subdirectory before SKILL.md. Reference files (docs, examples) go alongside SKILL.md as `references/`, `examples/` — not nested directories around it. Include a post-write verification step using Bash to confirm the file exists at the exact expected path.

**Warning signs:**
- Skill creator reports success but `/help` shows no new skill
- Session restart doesn't fix the missing skill (unlike the session-restart pitfall below)
- The skill file exists on disk but at a path like `~/.claude/skills/my-skill/my-skill/SKILL.md`

**Phase to address:** Skill creator skill (Phase 2). The path is a constant — bake it into the skill instructions and verify it with a post-write bash check.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| SKILL.md description is first-person ("I will improve your prompt") | Feels natural to write | Claude's skill router requires third-person; autonomous activation breaks | Never — always use third-person |
| Omit `argument-hint` from frontmatter | Fewer fields to write | Users see no hint in the `/` autocomplete; skill feels unfinished | Only if skill takes zero arguments |
| Hardcode absolute paths like `C:\Users\dev\.claude\skills\` | Works on author's machine | Breaks for all other users; unmaintainable | Never — always resolve home dynamically |
| Skip post-write validation in skill creator | Simpler skill body | Silent failures where skill saves but doesn't load | Only in initial prototyping, never in shipped skill |
| Generate CLAUDE.md content in a subagent from interview answers | Cleaner separation of concerns | Subagents lose main conversation context; interview answers become unavailable | Never for the workspace creator use case |
| Include all docs from `docs/` folder via file references in skill body | Gives Claude more context | Context rot — large doc sets eat 20-50% of context budget before any task starts | Only when docs/ contains ≤3 files under 2,000 tokens each |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `~/.claude/skills/` path on Windows | Using `~/` or `$HOME` assuming bash expansion; getting `C:/Program Files/Git/home/user` due to MSYS path mangling | Resolve with `echo "$USERPROFILE"` in a Bash tool call; construct path explicitly as `$USERPROFILE/.claude/skills/` |
| `AskUserQuestion` in subagents | Attempting to use AskUserQuestion from a spawned subagent | AskUserQuestion only works in the main Claude session — interview the user before spawning any subagents |
| Writing to `.claude/` directories | Assuming `.claude/` write exemption works on current Claude Code version | Pre-flight check the permission or use `settings.local.json` allow rules (see Critical Pitfall 2) |
| `docs/` folder file references in skill body | Using `@docs/` relative path from global `~/.claude/skills/` context | Global skills don't have a predictable working directory — reference docs via the skill-creator project's `CLAUDE_PLUGIN_ROOT` or require the user to specify an absolute path |
| Frontmatter backtick characters in SKILL.md | Writing code examples with backtick-fenced blocks in SKILL.md frontmatter or body | Issue #13932: skill tool passes SKILL.md through shell eval in some versions; backticks and single quotes can trigger shell parsing errors — escape or avoid in frontmatter; use indented code blocks in the body if necessary |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Loading entire `docs/` folder for every skill creator invocation | Skill creator is slow; context fills up leaving little room for the generated skill content | Read only the most relevant doc sections using targeted Bash reads (`grep -l <topic>` to find relevant files, then read those) | Any `docs/` folder larger than ~5 files or ~10,000 tokens total |
| CLAUDE.md generated by workspace creator exceeds 10K tokens | Claude Code's Read tool silently truncates the file; later sessions get incomplete context | Keep generated CLAUDE.md under 200 lines / 8,000 tokens; move detailed content to `.workspace/context/` reference files | The generated CLAUDE.md is the permanent context — if it gets truncated, all sessions are degraded |
| Skill body references many files via `@file` syntax | Each `@file` reference adds a full file read to the skill's token budget | Use references sparingly; prefer a single `references/` subdirectory with a summary file rather than direct multi-file `@` references | When referenced files collectively exceed ~15,000 tokens |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Writing generated skills to arbitrary user-specified paths | Skill creator could be tricked into writing to system directories or overwriting existing skills | Validate the skill name: reject names containing `/`, `..`, `\`, or spaces; restrict writes to `~/.claude/skills/<sanitized-name>/SKILL.md` only |
| Workspace creator creating directories without checking for existing content | Silently overwrites an existing `.workspace/` or `CLAUDE.md` that the user wanted to keep | Before writing any file: check if it exists; if it does, ask the user whether to overwrite, merge, or abort |
| Embedding sensitive content from `docs/` into generated skill instructions | Docs may contain API keys, credentials, internal URLs — they'd be embedded in the saved skill file | Warn user before reading `docs/` that its content will be embedded in the skill; don't embed raw file contents, only summaries |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Prompt improvement skill rewrites the user's prompt and discards the original | User can't compare old vs. new; can't tell what changed | Output the improved prompt in a clearly marked block; explicitly display what changed; never silently replace — always show both |
| Workspace creator asks 10+ questions before doing anything | User abandons the interview; never gets a workspace | Cap interview at 5-7 high-value questions; derive remaining details from answers already given; front-load the most impactful questions |
| Skill creator generates a skill with a vague name like `my-skill` | Skill is hard to find and invoke; collides with other skills | Require the user to provide a descriptive name before generation; suggest a name based on the described purpose; validate uniqueness against existing `~/.claude/skills/` |
| Prompt improvement skill fires on every input, even already-clear prompts | Friction; users feel overridden; expert users abandon the skill | Design as explicit invocation only (`/improve-prompt`) rather than autonomous activation; or implement a bypass prefix (`*`) that skips improvement for prompts that are already well-formed |
| Skill creator's interview produces a skill that Claude Code can't find after the session | User tests the new skill immediately, it doesn't work, they lose trust | Tell the user after saving: "Your new skill is now available. If you don't see it, restart Claude Code and check `~/.claude/skills/<name>/SKILL.md` exists." |

---

## "Looks Done But Isn't" Checklist

- [ ] **Skill creator output:** Verify the saved SKILL.md is at `~/.claude/skills/<name>/SKILL.md` (not nested deeper, not in project `.claude/`) — confirm with `ls ~/.claude/skills/`
- [ ] **Workspace creator output:** Verify the generated CLAUDE.md contains zero placeholder strings — `grep -i "placeholder\|TODO\|\[your\|<your" .workspace/../CLAUDE.md` should return nothing
- [ ] **Skill descriptions:** Every generated skill's `description` field uses third-person format and contains at least two quoted trigger phrases and one "Do NOT use for" clause
- [ ] **AskUserQuestion calls:** No single call has more than 4 options in the `options` array — check skill instructions for any list with 5+ items
- [ ] **Generated file paths:** All paths written by the workspace creator use forward slashes and are not hardcoded to a specific user's home directory
- [ ] **Prompt improvement output:** The improved prompt is presented alongside the original — user can see what changed before adopting it
- [ ] **Permission pre-flight:** The skill creator instructions include a note to configure `settings.local.json` if the user encounters permission prompts on write

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Skill saved to wrong location (project vs. global) | LOW | `mkdir -p ~/.claude/skills/<name> && cp .claude/skills/<name>/SKILL.md ~/.claude/skills/<name>/SKILL.md` |
| Skill not discoverable (nesting error) | LOW | Move SKILL.md up one directory level; restart session |
| Permission prompts blocking skill writes | LOW | Add `"Write(.claude/**)"` to `settings.local.json` permissions allow list |
| Generated CLAUDE.md is a stub | MEDIUM | Re-run workspace creator skill with explicit instructions to use interview answers; or manually populate from session history |
| Prompt improvement overwrites user's original intent | LOW | Conversation history contains the original; copy from history |
| Windows path error causes misplaced files | MEDIUM | Locate the misplaced directory, move it to the correct Windows path, update any references in skill instructions |

---

## Pitfall-to-Phase Mapping

| Pitfall | Skill | Verification |
|---------|-------|--------------|
| Skill saved to project scope instead of `~/.claude/skills/` | Skill creator (Phase 2) | After skill creation: `ls ~/.claude/skills/` shows new entry |
| Permission prompt regression (v2.1.79+) blocks skill write | Skill creator (Phase 2) | Skill creates without user confirmation prompt appearing |
| Windows path separator in generated paths | Workspace creator (Phase 3) + Skill creator (Phase 2) | File write succeeds on Windows without path-not-found errors |
| Vague skill description prevents autonomous activation | All three skills (Phases 1–3) | All three generated skill descriptions contain quoted trigger phrases in third-person format |
| AskUserQuestion 4-option limit crash | Workspace creator (Phase 3) + Skill creator (Phase 2) | No InputValidationError during interview; all option arrays have ≤4 items |
| Workspace creator generates stub CLAUDE.md | Workspace creator (Phase 3) | Grep for placeholder strings in generated CLAUDE.md returns empty |
| Skill nesting one level too deep | Skill creator (Phase 2) | Post-write bash check confirms path is exactly `~/.claude/skills/<name>/SKILL.md` |
| Docs context overflow in skill creator | Skill creator (Phase 2) | Skill creator reads only relevant docs sections; generated skill body is under 500 lines |
| Prompt improvement overwrites original intent | Prompt improvement skill (Phase 1) | Output includes both original and improved prompt, labeled |
| New skills directory requires session restart | Skill creator (Phase 2) | Skill creator instructions include a "restart if needed" note for first-time use |

---

## Sources

- GitHub Issue #16165 — Skills created in project directory instead of user directory (WSL): https://github.com/anthropics/claude-code/issues/16165
- GitHub Issue #36497 — `.claude/skills/` edits prompt for permission despite being documented as exempt (v2.1.79 regression): https://github.com/anthropics/claude-code/issues/36497
- GitHub Issue #12420 — AskUserQuestion tool limited to 4 options is too restrictive: https://github.com/anthropics/claude-code/issues/12420
- GitHub Issue #30553 — Claude should use platform-appropriate paths on Windows: https://github.com/anthropics/claude-code/issues/30553
- GitHub Issue #13932 — Skill tool fails on markdown files containing backticks or single quotes: https://github.com/anthropics/claude-code/issues/13932
- Context7/anthropics/claude-code — SKILL.md frontmatter format, trigger phrase requirements, third-person description pattern
- Context7/anthropics/claude-code — Command development skill, directory structure requirements, nesting rules
- MindStudio — Context rot in Claude Code skills (bloated SKILL.md degrades output quality): https://www.mindstudio.ai/blog/context-rot-claude-code-skills-bloated-files
- Scott Spence — How to make Claude Code skills activate reliably (20% vs. 84% activation rates): https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably
- DEV Community — Diagnostic CLI for Claude Code skills (8 structural rules, 14/23 skills had issues): https://dev.to/thestack_ai/i-built-a-diagnostic-cli-for-claude-code-skills-heres-what-8-rules-caught-that-i-missed-4142
- Agensi.io — Claude Code skills on Windows, path issues, CRLF line endings: https://www.agensi.io/learn/claude-code-skills-windows-setup
- Piebald AI — AskUserQuestion tool system prompt description (cannot use in subagents, plan-mode restriction): https://github.com/Piebald-AI/claude-code-system-prompts/blob/main/system-prompts/tool-description-askuserquestion.md
- severity1/claude-code-prompt-improver — Reference implementation for prompt improvement hook (token economy, bypass prefix design): https://github.com/severity1/claude-code-prompt-improver
- MindStudio — Overloading Claude Code with too many skills and CLAUDE.md size discipline: https://www.mindstudio.ai/blog/claude-code-skills-common-mistakes-guide

---
*Pitfalls research for: Claude Code skill development (prompt improver, skill creator, workspace creator)*
*Researched: 2026-04-26*
