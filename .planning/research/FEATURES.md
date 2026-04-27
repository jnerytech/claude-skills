# Feature Research

**Domain:** Claude Code skills (SKILL.md-based slash commands)
**Researched:** 2026-04-26
**Confidence:** HIGH — based on official Anthropic documentation, existing community implementations, and prior-art analysis

---

## Terminology Clarification

These deliverables are **Skills** (SKILL.md format), not plain slash commands. A skill is a directory with `SKILL.md` as entrypoint plus optional bundled resources (docs, scripts, templates). Skills support:

- YAML frontmatter (`name`, `description`, `allowed-tools`, `disable-model-invocation`, `context`, `argument-hint`, etc.)
- Bundled supporting files (`docs/`, `scripts/`, `examples/`) referenced from `SKILL.md`
- `$ARGUMENTS` substitution and named argument declarations
- Dynamic context injection via `!`backtick` shell execution
- Fork-context subagent execution via `context: fork`
- Live change detection without restarting Claude Code

Skills saved to `~/.claude/skills/` are available globally across all projects.

---

## Skill 1: Prompt Improvement Skill (`/improve-prompt`)

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Accepts rough prompt as `$ARGUMENTS` | Without this, the skill is useless — user must be able to pass their draft prompt inline | LOW | Standard `$ARGUMENTS` substitution |
| Outputs a single improved prompt in chat | User expects one clean result they can copy-paste or use immediately | LOW | Chat output, no file writes needed |
| Applies the 4 core clarity dimensions: context, specificity, structure, scope | These are the universally documented Claude Code prompt quality dimensions from Anthropic's own best-practices guide | MEDIUM | Clarity, specificity, context richness, structure |
| Preserves the user's original intent | An improved prompt that changes what the user wanted is worse than useless — it's deceptive | LOW | Must not reframe intent, only sharpen expression |
| Works for Claude Code task descriptions specifically | Generic "make my essay better" improvers miss code-task nuance (file references, tool hints, verification criteria) | MEDIUM | Domain-aware: output format, verification strategy, `@file` patterns |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Claude Code-specific idiom injection | Generic prompt improvers add "be specific" — ours adds `@file` references, verification asks ("run tests after"), and scope statements native to Claude Code | MEDIUM | Reference official Claude Code best-practice patterns from Anthropic docs |
| Adds verification criteria if missing | The single highest-leverage Claude Code tip (per official docs): give Claude a way to verify its own work. Most prompts omit this. | MEDIUM | Detect absence of test/screenshot/validation instruction and add one |
| Explains what changed and why | Teaches the user prompt engineering rather than just rewriting for them — increases user skill over time | LOW | Brief "What changed: [X because Y]" annotation after the improved prompt |
| Handles very short / vague inputs gracefully | "fix the bug" is a real input — the skill must surface what's missing rather than silently producing a poor rewrite | MEDIUM | For low-information inputs, output the improved prompt plus a note on what context would sharpen it further |
| `disable-model-invocation: true` | User controls when prompts get rewritten — Claude should not auto-rewrite prompts on its own judgment | LOW | One-line frontmatter change but important for trust |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Multiple rewrite variants (A/B options) | "Give me 3 versions" seems like more value | Adds decision fatigue; the user wants one good prompt, not a comparison task; community skill prompt-rewriter found 2-3 options added friction | Single best rewrite with an explanation of what changed |
| Scores/grading the input prompt | "7/10 clarity" seems informative | Scores have no actionable meaning without rubric; they distract from the improved output | A brief plain-language "What was weak: [X]" suffices |
| Generic prompt frameworks (CO-STAR, RISEN, etc.) | Prompt frameworks are popular in content about prompt engineering | These frameworks are designed for LLM API use, not Claude Code agentic tasks; applying them to code task descriptions produces unnatural output | Apply Claude Code-native patterns: context, scope, verification, file references |
| Full interview before rewriting | "Ask me questions first" seems thorough | Prompt improvement is a fast-turnaround task; an interview loop defeats the purpose of a quick rewrite utility | For low-information inputs, embed the "what's missing" note inside the output |

---

## Skill 2: Skill Creator Skill (`/create-skill`)

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Reads bundled `docs/` folder from the skill's own directory | PROJECT.md requirement; `${CLAUDE_SKILL_DIR}` substitution makes this reliable without hardcoded paths | LOW | Use `${CLAUDE_SKILL_DIR}/docs/` as the reference root |
| Multi-turn interview using `AskUserQuestion` | The skill's core mechanic — Claude interviews the user rather than generating a skill from a single vague description | MEDIUM | Structured interview with ~4-6 targeted questions |
| Saves the generated SKILL.md to `~/.claude/skills/<name>/SKILL.md` | Without writing to the global skills dir, the output has no effect — user would have to copy-paste manually | MEDIUM | Requires `Write` tool permission; confirm path with user before writing |
| Generates valid SKILL.md frontmatter | Malformed frontmatter breaks the skill silently — generated file must have correct YAML structure | LOW | At minimum: `name`, `description`; optionally `disable-model-invocation`, `argument-hint`, `allowed-tools` |
| Generates a real markdown instruction body (not a stub) | "Write your instructions here" stubs are useless — the output must be immediately usable | HIGH | This is where most of the work lives: translating interview answers into working skill instructions |
| Confirms the output with the user before writing | Skill creation is a write-to-`~/.claude/` operation with global scope — user must approve before file is written | LOW | Show the generated SKILL.md in chat, ask for confirmation |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Proposes answers, doesn't ask blank questions | The best interview pattern from community research: "I'd recommend `disable-model-invocation: true` for this because it has side effects — does that fit?" vs. "Should this be manually triggered?" | MEDIUM | For each question, surface a recommended answer with rationale; user confirms, adjusts, or overrides |
| Reads Claude Code docs from `docs/` to ground output | The skill creator's output is only as good as its knowledge of what a skill can do; reading current local docs prevents hallucinating non-existent frontmatter fields | HIGH | `${CLAUDE_SKILL_DIR}/docs/` lookup before generating; cite specific docs concepts in generated skill |
| Asks about test cases and proposes 2-3 example prompts | Official Anthropic skill-creator includes eval/test generation; testing is the feedback loop that improves skills | MEDIUM | Output includes "example invocations" block showing 2-3 sample `/skill-name <args>` calls |
| Detects skill type and adjusts frontmatter accordingly | Task skills (side effects) need `disable-model-invocation: true`; reference skills don't; the skill creator should reason about this | MEDIUM | Interview question: "Is this something Claude should trigger automatically, or only when you type /name?" |
| Supports bundled resource pattern | Point user toward adding `scripts/`, `examples/`, or `reference.md` files when the skill is complex | LOW | At end of generation, offer: "This skill could benefit from a bundled [script/template/reference] — want me to scaffold that too?" |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Exhaustive interview (10+ questions) | "Cover all cases" instinct | More questions = more friction; diminishing returns after ~6 targeted questions; user abandonment before completion | 4-6 questions max; each must extract something that changes the output if answered differently |
| Validate the generated skill by running it | "Test the skill right now" seems thorough | Skill invocation mid-skill-creation creates a recursive loop risk; it also requires the skill to be written first | Provide example invocations the user can test manually after writing the file |
| Sync/version/update mechanism | "Keep skills up to date" | Out of scope per PROJECT.md; adds complexity to a v1 tool | Noted as future consideration in PROJECT.md |
| Fetch docs from the web | "Always latest docs" | PROJECT.md explicitly requires local `docs/` only — no live web fetches; offline reliability is a design goal | Pre-downloaded docs in `docs/` folder within the skill directory |

### Interview Question Design (Table Stakes Detail)

These 5-6 questions extract the information needed to build a skill that works on first invocation. Each question proposes an answer:

1. **What does this skill do?** (Capture: name, description, core task)
2. **When should Claude trigger it automatically vs. only on explicit /name call?** — Propose: "manually triggered, since it [has side effects / is a long workflow]" (Capture: `disable-model-invocation`)
3. **What arguments does the user pass, if any?** — Propose: "no arguments, the skill operates on current context" (Capture: `arguments`, `argument-hint`)
4. **What tools should this skill be allowed to use without permission prompts?** — Propose based on task type: "Bash for git ops, Read/Write for file tasks" (Capture: `allowed-tools`)
5. **Can you give me an example of a real invocation — what would you type?** (Capture: generates example invocations, test cases)
6. **What does a good output look like?** (Capture: output format, success criteria for the instruction body)

---

## Skill 3: Workspace Creator Skill (`/create-workspace`)

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Guided interview: asks workspace name, repos, purpose | Without this, the user is just filling in a template manually — no value over a `cp -r template .` | LOW | 3-5 focused questions before any scaffolding begins |
| Scaffolds the full `.workspace/` directory structure | PROJECT.md requirement: `refs/`, `docs/`, `logs/`, `scratch/`, `context/`, `outputs/`, `sessions/` | LOW | `Bash(mkdir -p ...)` calls; straightforward once directories are defined |
| Scaffolds `.claude/` and `.vscode/` directories | Part of the opinionated workspace convention | LOW | Empty dirs + placeholder files (e.g., `.vscode/settings.json`) |
| Generates a **populated** CLAUDE.md — not a stub | PROJECT.md hard requirement: "must generate populated CLAUDE.md content from interview answers, not leave stubs" | HIGH | This is the highest-complexity output; drives interview design |
| CLAUDE.md covers: workspace purpose, repo map, session conventions | These are the three pieces of context that make a CLAUDE.md immediately useful per official docs and community patterns | MEDIUM | Purpose = why this workspace exists; repo map = which dirs are which repos; conventions = how to use `.workspace/` subdirs |
| Confirms full scaffold with user before writing | Writing a workspace structure is a multi-file operation; one wrong path = broken setup | LOW | Show directory tree in chat, ask for confirmation |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| CLAUDE.md repo map derived from interview answers | Most CLAUDE.md generators produce generic stubs; ours maps actual repo names to purpose, based on what the user said during the interview | HIGH | "You said `frontend` is a Next.js app and `api` is a Fastify service — here's the repo map section" |
| `.workspace/` subdirectory README stubs with purpose explanations | Empty dirs confuse future Claude sessions; a one-line `README.md` in each subdir explains what goes there | LOW | `refs/` = external docs & links; `docs/` = generated documents; `logs/` = session logs; `scratch/` = throwaway work; `context/` = persisted context files; `outputs/` = final artifacts; `sessions/` = session notes |
| CLAUDE.md uses `@import` pattern for modularity | Official Anthropic pattern: root CLAUDE.md stays short (<200 lines) and imports topic-specific files | MEDIUM | Generate `CLAUDE.md` + `.claude/rules/conventions.md` imported via `@.claude/rules/conventions.md` |
| Session convention block in CLAUDE.md | Many workspaces fail because Claude doesn't know how to organize session outputs; explicit conventions prevent this | LOW | "Session notes go in `.workspace/sessions/YYYY-MM-DD-topic.md`; scratch work goes in `.workspace/scratch/`" |
| Validates workspace name for path safety | Workspace names become directory names; spaces, special chars break paths | LOW | Sanitize input before writing any paths |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Full CLAUDE.md with code style, linting, test commands | "Make it comprehensive" | Workspace-level CLAUDE.md should carry workspace context, not per-repo conventions; per-repo conventions belong in each repo's own CLAUDE.md | Generate workspace CLAUDE.md covering workspace structure only; note in output: "add per-repo conventions to each repo's own CLAUDE.md" |
| Generate `.vscode/extensions.json` with specific extensions | "Set up my editor too" | Extension choices are personal; hardcoding them creates wrong defaults for others sharing the workspace | Generate an empty `.vscode/` with placeholder `settings.json`; leave extension choices to user |
| MCP server configuration | "Set up tools too" | MCP config is project-specific and requires credentials; generating it without user-specific values produces broken configs | Out of v1 scope per PROJECT.md |
| Automatically add all subdirs to git | "Initialize the workspace as a repo" | Workspace may contain repos that are already git repos; `git init` at workspace root creates nested git problems | Leave git setup to user; note in output: "if you want to version control workspace docs, run `git init` in `.workspace/`" |

### Interview Question Design (Table Stakes Detail)

These 4-5 questions extract the information needed to produce a real CLAUDE.md, not a stub:

1. **What is this workspace called?** — Becomes the workspace root directory name and CLAUDE.md title (Capture: `name`, path)
2. **What repos will live here?** — List the directory names: "frontend, api, shared" (Capture: repo map for CLAUDE.md)
3. **What is each repo / what does it do?** — One sentence per repo (Capture: populates repo map descriptions in CLAUDE.md)
4. **What is the overall purpose of this workspace?** — "Building the v2 rewrite of X" or "exploring ML approaches for Y" (Capture: purpose section in CLAUDE.md)
5. **Any conventions for how you'll use Claude Code here?** — Propose defaults: "Session notes in `.workspace/sessions/`, reference material in `.workspace/refs/`, scratch in `.workspace/scratch/`" (Capture: session conventions block)

---

## Cross-Skill Feature Dependencies

```
[Prompt Improvement Skill]
    - no dependencies; standalone

[Skill Creator Skill]
    └──requires──> bundled docs/ in skill directory (pre-populated by project setup)
    └──requires──> Write tool permission (to save ~/.claude/skills/<name>/SKILL.md)
    └──enhances──> [Workspace Creator Skill] (could be used to create workspace-specific skills after setup)

[Workspace Creator Skill]
    └──requires──> Bash tool permission (mkdir, write files)
    └──requires──> Write tool permission (CLAUDE.md, README stubs)
    └──produces──> .claude/ directory that could house project skills from Skill Creator
```

### Dependency Notes

- **Skill Creator requires bundled docs/**: The quality of the generated SKILL.md is directly proportional to the quality of Claude Code documentation in `docs/`. The docs folder must be pre-populated as part of project setup, not at skill invocation time.
- **Workspace Creator requires Bash + Write**: Multiple files and directories must be created. The `allowed-tools` frontmatter for this skill should pre-approve `Bash(mkdir *)` and `Write`.
- **Skill Creator enhances Workspace Creator**: After a workspace is set up, the user might want workspace-specific skills. The two skills are independent but their outputs compose naturally.

---

## MVP Definition

### Launch With (v1)

All three skills must ship together — they are the stated v1 scope. Within each skill:

**Prompt Improvement Skill**
- [ ] `$ARGUMENTS` intake of the rough prompt — essential
- [ ] Single improved prompt output in chat — essential
- [ ] 4 core dimensions applied: context, specificity, structure, scope — essential
- [ ] "What changed" annotation — essential (teaches rather than just rewrites)
- [ ] `disable-model-invocation: true` — essential (user controls timing)

**Skill Creator Skill**
- [ ] Reads `${CLAUDE_SKILL_DIR}/docs/` before generating — essential
- [ ] 5-6 question interview with proposed answers — essential
- [ ] Valid SKILL.md frontmatter generated — essential
- [ ] Real instruction body generated (not stub) — essential
- [ ] Confirms output before writing to `~/.claude/skills/` — essential

**Workspace Creator Skill**
- [ ] 4-5 question interview — essential
- [ ] Full `.workspace/` directory scaffold — essential
- [ ] Populated CLAUDE.md (purpose + repo map + conventions) — essential (hard requirement per PROJECT.md)
- [ ] Subdirectory README stubs — essential (prevents confusion in later Claude sessions)
- [ ] Confirmation before writing — essential

### Add After Validation (v1.x)

- [ ] Prompt Improvement: detect when input is too vague and surface a "what's missing" note inline — add when users report confusing rewrites
- [ ] Skill Creator: bundled resource scaffolding offer (scripts/, examples/) — add when users want more complex skills
- [ ] Workspace Creator: `@import` pattern for CLAUDE.md modularity — add when generated files exceed 150 lines
- [ ] Skill Creator: generate example invocation block as part of output — add when user feedback shows testing confusion

### Future Consideration (v2+)

- [ ] Skill versioning/update mechanism — explicitly out of v1 scope per PROJECT.md
- [ ] Skill Creator: automated test-case runner — requires subagent orchestration; adds significant complexity
- [ ] MCP server configuration generation — requires credential handling; out of v1 scope per PROJECT.md
- [ ] Prompt Improvement: conversation-aware mode (uses session history as context for the rewrite) — high value but adds stateful complexity

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Prompt rewrite with 4 dimensions | HIGH | LOW | P1 |
| "What changed" annotation | HIGH | LOW | P1 |
| Skill creator interview (5-6 questions w/ proposed answers) | HIGH | MEDIUM | P1 |
| Skill creator saves to `~/.claude/skills/` | HIGH | MEDIUM | P1 |
| Workspace CLAUDE.md population | HIGH | HIGH | P1 |
| Workspace directory scaffold | HIGH | LOW | P1 |
| Subdirectory README stubs | MEDIUM | LOW | P1 |
| Skill creator reads docs/ before generating | HIGH | MEDIUM | P1 |
| Confirmation before write operations | HIGH | LOW | P1 |
| Multiple prompt rewrite variants | LOW | MEDIUM | P3 |
| Prompt scoring/grading | LOW | MEDIUM | P3 |
| Skill creator automated test runner | MEDIUM | HIGH | P3 |
| MCP configuration generation | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Competitor / Prior Art Feature Analysis

| Feature | Severity1 Prompt Improver (Hook) | Ckelsoe Prompt Architect (Skill) | OpenClaw Prompt Rewriter (Skill) | Our Approach |
|---------|-----------------------------------|----------------------------------|----------------------------------|--------------|
| Intercept mechanism | Hook (pre-prompt) | Skill (on demand) | Skill (on demand) | Skill (on demand) — user controls when |
| Output | Single improved + questions | Scored rewrite with framework | 2-3 variants | Single improved + "what changed" |
| Framework-based | No | Yes (27 frameworks) | Yes (CoT, few-shot) | No — Claude Code-native patterns only |
| Claude Code idioms | Partial | No | No | Yes — @file, verification, scope |
| Token overhead | 31% reduction focus | Heavy (scoring + analysis) | Medium | Minimal — one clean output |

| Feature | Anthropic skill-creator skill | Our Skill Creator |
|---------|------------------------------|-------------------|
| Interview approach | Iterative with test/eval loop | 5-6 questions with proposed answers, confirm before write |
| Test generation | Yes (full eval framework) | v1: example invocations only; eval in v2+ |
| Docs reading | No (general knowledge) | Yes — reads `${CLAUDE_SKILL_DIR}/docs/` |
| Save to disk | User must do it | Writes directly to `~/.claude/skills/` after confirmation |

---

## Sources

- [Extend Claude with Skills — Official Anthropic Docs](https://code.claude.com/docs/en/skills)
- [Best Practices for Claude Code — Official Anthropic Docs](https://code.claude.com/docs/en/best-practices)
- [How Claude remembers your project (CLAUDE.md) — Official Anthropic Docs](https://code.claude.com/docs/en/memory)
- [Anthropic official skill-creator SKILL.md — GitHub](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md)
- [Claude Code Prompt Improver (severity1) — GitHub](https://github.com/severity1/claude-code-prompt-improver)
- [Prompt Architect (ckelsoe) — GitHub](https://github.com/ckelsoe/prompt-architect)
- [Prompt Rewriter skill (openclaw) — Playbooks](https://playbooks.com/skills/openclaw/skills/prompt-rewriter)
- [Writing a good CLAUDE.md — HumanLayer Blog](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Creating the Perfect CLAUDE.md — Dometrain](https://dometrain.com/blog/creating-the-perfect-claudemd-for-claude-code/)
- [Multi-Turn Interview Patterns with AskUserQuestion — NeonWatty](https://neonwatty.com/posts/interview-skills-claude-code/)
- [Skills vs Slash Commands — Rewire.it](https://rewire.it/blog/claude-code-agents-skills-slash-commands/)
- [Awesome Claude Code (community resource list) — GitHub](https://github.com/hesreallyhim/awesome-claude-code)

---

*Feature research for: Claude Code skills plugin (prompt improvement, skill creator, workspace creator)*
*Researched: 2026-04-26*
