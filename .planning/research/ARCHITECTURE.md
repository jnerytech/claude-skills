# Architecture Research

**Domain:** Claude Code plugin — set of slash-command skills
**Researched:** 2026-04-26
**Confidence:** HIGH (based on reading installed plugin sources, official marketplace examples, and GSD skill corpus directly from the filesystem)

---

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Plugin Package (repo root)                  │
│                                                                  │
│  README.md      .claude-plugin/plugin.json    .mcp.json(opt)    │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                       skills/                             │   │
│  │                                                           │   │
│  │  ┌─────────────────┐  ┌──────────────┐  ┌────────────┐  │   │
│  │  │ prompt-improve/ │  │skill-create/ │  │workspace-  │  │   │
│  │  │                 │  │              │  │create/     │  │   │
│  │  │ SKILL.md        │  │ SKILL.md     │  │            │  │   │
│  │  │ (self-contained)│  │ references/  │  │ SKILL.md   │  │   │
│  │  │                 │  │   *.md       │  │ templates/ │  │   │
│  │  └─────────────────┘  └──────────────┘  │   *.md     │  │   │
│  │                                          └────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  docs/                    (pre-downloaded Claude Code docs)      │
│  ├── index.md             (topic map — skill-creator reads this) │
│  └── [topic subdirs]/                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
         │ user runs /plugin install claude-skills@<marketplace>
         ▼
~/.claude/plugins/cache/<marketplace>/claude-skills/<version>/
         │
         │  Skills load directly from cache — NOT copied to ~/.claude/skills/
         │  ~/.claude/skills/ is where individually-installed standalone skills live
         │  (e.g., GSD corpus). Plugin skills load from their cache path.
         │
         │  skill-create WRITES to ~/.claude/skills/ (user-authored output only)
         ▼
~/.claude/skills/<user-authored-skill-name>/SKILL.md
```

**Two distinct locations, two distinct purposes:**

| Location | Contents | Who puts things there |
|----------|----------|----------------------|
| `~/.claude/plugins/cache/.../skills/` | This plugin's skills (at runtime) | `/plugin install` copies plugin here |
| `~/.claude/skills/` | Individually-installed standalone skills | User or skill-create writes here |

### Component Responsibilities

| Component | Responsibility | Notes |
|-----------|----------------|-------|
| `skills/prompt-improve/SKILL.md` | Rewrite rough user prompt → polished version; outputs in chat | Zero filesystem ops; self-contained in SKILL.md body |
| `skills/skill-create/SKILL.md` | Interview user, read `docs/` in repo, emit SKILL.md to `~/.claude/skills/<name>/` | Reads local docs; writes one directory + one file |
| `skills/skill-create/references/` | Curated excerpts from Claude Code docs loaded on demand | Avoids stuffing all docs into SKILL.md context window |
| `skills/workspace-create/SKILL.md` | Interview user, scaffold `.workspace/` + `.claude/` + `CLAUDE.md` | Multi-dir filesystem ops; heaviest file-system surface |
| `skills/workspace-create/templates/` | Mustache-style CLAUDE.md template, dir manifest | Keeps SKILL.md body under 500 lines |
| `docs/` (repo root) | Pre-downloaded Claude Code documentation for skill-creator to reference | No network fetch; offline-first |
| `docs/index.md` | Topic map: section name → file path + one-line summary | Skill-creator reads this first; loads specific files on demand |
| `.claude-plugin/plugin.json` | Plugin metadata for marketplace distribution | Required for `/plugin install` flow |
| `README.md` | Human-facing install and usage docs | Not loaded into Claude context at runtime |

---

## Recommended Project Structure

```
claude-skills/                      # repo root
├── .claude-plugin/
│   └── plugin.json                 # name, description, author (verified schema)
├── skills/
│   ├── prompt-improve/
│   │   └── SKILL.md                # self-contained; no supporting files needed
│   ├── skill-create/
│   │   ├── SKILL.md                # orchestrator; references docs/ index
│   │   └── references/
│   │       ├── skill-anatomy.md    # what goes in frontmatter, body, supporting dirs
│   │       ├── writing-guide.md    # description field, triggering, patterns
│   │       └── naming-conventions.md  # kebab-case, collision handling
│   └── workspace-create/
│       ├── SKILL.md                # interview flow + scaffold instructions
│       └── templates/
│           ├── CLAUDE.md.template  # workspace CLAUDE.md with {{placeholders}}
│           └── dir-manifest.md     # canonical list of dirs to create
├── docs/                           # pre-downloaded Claude Code docs
│   ├── index.md                    # REQUIRED: topic → file path map
│   ├── skills/
│   │   ├── overview.md
│   │   ├── frontmatter.md
│   │   └── bundled-resources.md
│   ├── commands/
│   │   └── slash-commands.md
│   └── plugins/
│       ├── structure.md
│       └── publishing.md
├── README.md
└── .planning/                      # GSD project planning (not shipped in plugin)
```

### Structure Rationale

- **`skills/<name>/SKILL.md` (not `commands/<name>.md`):** The official example plugin explicitly marks `commands/` as legacy. All new plugins use `skills/<skill-dir>/SKILL.md`. Both load identically; the skills layout is canonical going forward.
- **`skills/skill-create/references/`:** The official skill-creator SKILL.md itself uses a `references/` subdir for schemas and agent instructions. Matches the three-tier progressive disclosure pattern: frontmatter metadata (~100 words, always in context) → SKILL.md body (<500 lines, in context when triggered) → references/ (loaded on demand). This keeps the skill-creator's SKILL.md under the 500-line target while still providing rich doc coverage.
- **`skills/workspace-create/templates/`:** Separating the CLAUDE.md template and dir manifest from SKILL.md body means the orchestrating instructions stay readable. Templates are populated by Write tool calls inside the skill's execution; they're not auto-loaded.
- **`docs/index.md`:** The skill-creator must not load all docs upfront (context budget). An index file lets it load specific referenced files on demand — the same pattern used in `references/` subdirs inside the official skill-creator.
- **No shared `workflows/` or `references/` at repo root:** The three skills share no significant logic. A shared layer adds indirection with no consumer. If future skills emerge that need common patterns (e.g., AskUserQuestion interview scaffolding), extract then — not now.

---

## plugin.json Schema (Verified)

Read from `anthropics/claude-plugins-official` — official Anthropic examples:

```json
{
  "name": "claude-skills",
  "description": "Three Claude Code skills: prompt rewriter, skill generator, and workspace scaffolder",
  "author": {
    "name": "Your Name",
    "email": "you@example.com"
  }
}
```

**Confirmed fields:** `name`, `description`, `author` (object with `name` and `email`). No `version` field in verified official examples. File lives at `.claude-plugin/plugin.json`, not at repo root.

---

## Skill Anatomy (Canonical Format)

Every skill file follows this exact structure. PROJECT.md mentions `<skill>` structure informally; the actual format is YAML frontmatter + Markdown body.

### User-Invoked Skill (slash command)

```yaml
---
name: skill-name           # becomes /skill-name; matches directory name
description: Short description shown in /help and used for model-invoked triggering
argument-hint: <required> [optional]
allowed-tools: [Read, Write, Bash, AskUserQuestion]
---

<objective>
What this skill does in 1-2 sentences.
</objective>

<context>
$ARGUMENTS
</context>

<process>
Step-by-step instructions. Reference supporting files via relative paths.
Load references/foo.md when handling X.
</process>
```

**Key frontmatter fields (verified against official sources):**

| Field | Required | Purpose |
|-------|----------|---------|
| `name` | Yes | Slash command identifier; must match directory name |
| `description` | Yes | Shown in /help; also primary triggering mechanism for model-invoked use |
| `argument-hint` | No | Shown to user as argument hint |
| `allowed-tools` | No | Pre-approved tools; reduces per-session permission prompts |
| `model` | No | Override model (haiku/sonnet/opus) |
| `version` | No | Semantic version for published plugins |

### Model-Invoked Skill (no slash command)

Same structure but omit `argument-hint` and `allowed-tools`. Description must be highly specific about trigger conditions — the description field is the sole triggering signal. Claude only consults skills for multi-step tasks it can't handle trivially; simple one-liners will not trigger even with a matching description.

---

## Data Flow

### Skill 1: Prompt Improve

```
User invokes /prompt-improve "rough prompt text"
    │
    ▼
$ARGUMENTS parsed → full prompt body as raw text (DATA boundary)
    │
    ▼
SKILL.md instructions applied:
  - Analyze: clarity, specificity, context richness, structure
  - Rewrite → improved version
    │
    ▼
Output: improved prompt printed to chat (no filesystem writes)
```

**Key boundary:** The user's rough prompt is data, not an instruction. The skill must treat $ARGUMENTS content as bounded user data to avoid prompt injection.

### Skill 2: Skill Creator

```
User invokes /skill-create "I want a skill that does X"
    │
    ▼
SKILL.md orchestrates:
  ┌─ 1. Read docs/index.md → identify relevant doc files
  ├─ 2. Read relevant docs/[topic]/*.md files (on demand, not upfront)
  ├─ 3. AskUserQuestion interview:
  │      - What should the skill do?
  │      - When should it trigger?
  │      - Expected output format?
  │      - Tool permissions needed?
  └─ 4. Generate SKILL.md content from interview answers + doc context
    │
    ▼
Path resolution:
  - Skill name → kebab-case from user's description
  - Target: ~/.claude/skills/<skill-name>/SKILL.md
  - On Windows: resolve ~ via $HOME or %USERPROFILE%
  - Collision check: does ~/.claude/skills/<name>/ already exist?
    If yes: prompt user — overwrite or rename?
    │
    ▼
Write tool calls:
  - mkdir ~/.claude/skills/<skill-name>/      (Bash: mkdir -p)
  - Write ~/.claude/skills/<skill-name>/SKILL.md
    │
    ▼
Confirmation: "Skill saved to ~/.claude/skills/<skill-name>/SKILL.md"
```

**Key boundary:** `docs/` is read-only reference material. Skill never writes to `docs/`. Output is always under `~/.claude/skills/`.

**Meta-bootstrap risk:** The skill-creator skill is itself a SKILL.md. Its output (the generated skill) follows the same format it is written in. This is a feature (it can use itself as a worked example) but also a risk: if the skill-creator's own frontmatter or structure drifts from the canonical format, it will produce subtly wrong output. The `references/skill-anatomy.md` file must be treated as the authoritative spec.

**Overlap with official Anthropic plugin:** Anthropic ships a `skill-creator` plugin in the official marketplace (`anthropics/claude-plugins-official`). It is substantially more powerful (evals, benchmarks, description optimization, packaging scripts, subagent eval loop). This project's skill-create is intentionally simpler: docs-driven, offline-first, interview-based. The naming differs (`skill-create` vs `skill-creator`) and the scope differs enough that they serve different use cases. However: if users have the official `skill-creator` installed, invocation might be ambiguous. See PITFALLS.md for the naming collision concern.

### Skill 3: Workspace Creator

```
User invokes /workspace-create
    │
    ▼
AskUserQuestion interview:
  - Workspace name?
  - Repos to include? (names/paths)
  - Workspace purpose? (1-2 sentences → CLAUDE.md context section)
    │
    ▼
Template population:
  - Load templates/CLAUDE.md.template
  - Replace {{workspace_name}}, {{repos}}, {{purpose}}, {{date}} placeholders
  - Render final CLAUDE.md content string
    │
    ▼
Filesystem scaffold (Bash: mkdir -p for each, Write for files):
  .workspace/
  ├── refs/
  ├── docs/
  ├── logs/
  ├── scratch/
  ├── context/
  ├── outputs/
  └── sessions/
  .claude/
  .vscode/
  CLAUDE.md             ← populated from template + interview answers
    │
    ▼
Confirmation summary: list of created dirs + CLAUDE.md path
```

**Key constraint from PROJECT.md:** CLAUDE.md must be populated from interview answers, not left as a stub. The template approach (load template → fill → Write) guarantees populated output.

**Filesystem safety:** All paths are relative to cwd (the workspace root where user runs the command). No absolute paths constructed from user input; no path traversal risk. Validation: if any target dir already exists, report conflict and ask before overwriting.

---

## Architectural Patterns

### Pattern 1: Progressive Disclosure via References Subdir

**What:** SKILL.md body stays under 500 lines by externalizing large reference content to `references/*.md` files, loaded only when relevant.

**When to use:** Any skill whose domain has non-trivial reference content (skill-creator, workspace-create). Not needed for prompt-improve (pure text transformation, no external reference).

**Trade-offs:** Slight overhead of one extra Read call per reference file. Benefit: SKILL.md stays legible, reference files can be updated independently.

**Example (skill-create/SKILL.md):**
```markdown
## Writing the Skill

Follow the canonical anatomy. Read references/skill-anatomy.md for the full
frontmatter spec and references/writing-guide.md for description field patterns.
```

### Pattern 2: Interview-Then-Write

**What:** Skill gathers structured user input via AskUserQuestion before any filesystem write. No speculative writes.

**When to use:** skill-create and workspace-create — both produce persistent artifacts from user intent.

**Trade-offs:** Adds interaction steps. Benefit: no half-baked output on disk from misunderstood intent; easier to confirm before committing writes.

### Pattern 3: Template + Substitution for CLAUDE.md

**What:** CLAUDE.md content is generated by loading a template file from `templates/`, substituting `{{placeholder}}` values from interview answers, then writing the result via Write tool.

**When to use:** workspace-create only. Centralizes CLAUDE.md structure decisions in one place; SKILL.md body stays focused on the interview flow.

**Trade-offs:** Template must stay in sync with the placeholders the interview collects. If a new interview question is added, the template must also be updated.

### Pattern 4: Docs Index + On-Demand Loading

**What:** `docs/index.md` is a topic map (section name → file path + one-line summary). The skill-creator reads the index first, then loads only the relevant doc files for the user's specific skill request.

**When to use:** skill-create only. Avoids loading the entire docs/ corpus into context for every invocation.

**Trade-offs:** Requires maintaining the index as docs/ is populated. Benefit: context budget scales with task specificity, not docs/ total size.

---

## Anti-Patterns

### Anti-Pattern 1: Self-Contained Mega-SKILL.md

**What people do:** Embed all reference content, templates, and doc excerpts directly in SKILL.md body to avoid maintaining supporting files.

**Why it's wrong:** SKILL.md body is always loaded into context when the skill triggers. A 2000-line SKILL.md wastes context on every invocation. The 500-line guideline from the official skill-creator is empirically derived.

**Do this instead:** Keep SKILL.md under 500 lines. Externalize reference content to `references/`. Use clear "read references/foo.md for X" pointers in the SKILL.md body.

### Anti-Pattern 2: Shared Workflow Layer for Three Skills

**What people do:** Create a `shared/` or `workflows/` directory at repo root with common interview scaffolding and output formatting used by all three skills.

**Why it's wrong:** The three skills share no runtime logic. Shared files are only useful if they're `@`-referenced from SKILL.md files, but Claude Code skills don't auto-load files outside their own skill directory unless explicitly instructed. Shared infrastructure has no consumer; it just adds complexity.

**Do this instead:** If two skills duplicate more than ~10 lines of identical process instructions, copy-paste is acceptable. Extract shared content only when three or more skills actively consume it.

### Anti-Pattern 3: Writing to `docs/` from skill-create

**What people do:** Have the skill-creator update `docs/` with newly discovered information during a session.

**Why it's wrong:** `docs/` is a static reference corpus, pre-downloaded by the user. It's not a live database. Writing to it during a session creates an unpredictable state that differs from the repo's committed content.

**Do this instead:** `docs/` is read-only at runtime. skill-creator only writes to `~/.claude/skills/<name>/`.

### Anti-Pattern 4: Absolute `~/.claude/skills/` Path Hardcoding

**What people do:** Hardcode `/Users/<name>/.claude/skills/` or `C:\Users\<name>\.claude\skills\` in the skill instructions.

**Why it's wrong:** Path is user-specific. On Windows vs. macOS the format differs. `~` expansion is also environment-dependent in some tools.

**Do this instead:** Use `$HOME/.claude/skills/<name>/` in instructions and resolve at runtime with `Bash: echo $HOME` or `Bash: echo %USERPROFILE%`. Let the Write tool receive the resolved absolute path.

### Anti-Pattern 5: `commands/` Layout for New Skills

**What people do:** Put skills at `commands/prompt-improve.md` because it's simpler (flat file).

**Why it's wrong:** The official example plugin marks `commands/*.md` as the legacy format. Both load identically today, but the `skills/<name>/SKILL.md` layout is the forward-compatible format and supports supporting files (references/, templates/) naturally.

**Do this instead:** Always use `skills/<skill-name>/SKILL.md`.

---

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| `~/.claude/skills/` | Write tool (Write + Bash mkdir) | skill-create output only; NOT where this plugin's own skills live |
| Claude Code plugin system | `.claude-plugin/plugin.json` + `skills/` structure | Enables `/plugin install` marketplace flow; plugin skills load from cache |
| User filesystem (cwd) | Bash mkdir + Write tool | workspace-create scaffolds dirs relative to cwd |
| `docs/` (local) | Read tool | skill-create reads; never writes |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| SKILL.md body ↔ references/ | Read tool call at runtime | SKILL.md explicitly instructs when to load which reference |
| SKILL.md body ↔ templates/ | Read tool call at runtime | workspace-create loads template, populates, writes result |
| skill-create ↔ docs/ | Read tool (index first, then specific files) | One-way: skill reads docs, never modifies |
| Any skill ↔ $ARGUMENTS | $ARGUMENTS substitution at invocation | User input; treat as bounded data, not trusted instructions |

---

## Build Order Implications

The three skills have a clear dependency gradient that should drive phase ordering:

**Phase 1 — prompt-improve**
- Zero dependencies on external files or filesystem writes
- Output is chat text only
- Establishes and validates the SKILL.md authoring conventions and plugin packaging for the repo
- Shortest feedback loop; confirms that `.claude-plugin/plugin.json` + `skills/` structure works end-to-end before building complex skills

**Phase 2 — skill-create**
- Depends on `docs/` folder existing and being indexed (user must download docs before this skill is useful)
- Writes to `~/.claude/skills/` — exercises path resolution and naming conventions that must be right before this skill ships
- The skill-create SKILL.md is itself a worked example of the format it must produce (meta-bootstrap opportunity and risk)
- Requires `references/skill-anatomy.md` to be authoritative; draft it during this phase
- Naming note: Anthropic's official `skill-creator` plugin covers similar ground. Differentiate clearly in the description field and README.

**Phase 3 — workspace-create**
- Most filesystem surface area (7+ directories + CLAUDE.md)
- Depends on template design being finalized before writing SKILL.md instructions
- Benefits from prompt-improve patterns (interview quality) and skill-create conventions (SKILL.md structure) both being stable
- No runtime dependency on skill-create; can be built independently but benefits from lessons learned

**Rationale for this order:** Each later skill can use the prior skill as a precedent and live test case. The prompt-improve skill validates the plugin packaging mechanism with zero risk. The skill-create skill validates global write paths. The workspace-create skill can rely on both being stable when it ships.

---

## docs/ Organization

The `docs/` folder serves one consumer: skill-create. It must be organized for that consumer's access pattern: "find the right file fast, load only what's needed."

**Recommended structure:**

```
docs/
├── index.md              # REQUIRED: topic → filepath + one-liner
├── skills/
│   ├── overview.md       # What skills are; model-invoked vs user-invoked
│   ├── frontmatter.md    # All frontmatter fields with types and examples
│   ├── anatomy.md        # Directory structure; references/, scripts/, assets/
│   └── writing-guide.md  # Description field; progressive disclosure; patterns
├── commands/
│   └── slash-commands.md # Legacy commands/ vs skills/; argument handling
└── plugins/
    ├── structure.md       # plugin.json; skills/ vs commands/ vs agents/
    └── publishing.md      # Marketplace submission; install scopes
```

**index.md format:**

```markdown
# Claude Code Docs Index

| Topic | File | Summary |
|-------|------|---------|
| Skill frontmatter fields | skills/frontmatter.md | name, description, allowed-tools, model |
| Skill directory anatomy | skills/anatomy.md | SKILL.md + references/ + scripts/ + assets/ |
| Writing effective descriptions | skills/writing-guide.md | Triggering, progressive disclosure, patterns |
| Plugin structure | plugins/structure.md | plugin.json, skills/, commands/, agents/ |
```

**Access pattern the index enables:**

1. skill-create reads `docs/index.md` → finds topic → reads specific file
2. Only 1-2 files loaded per invocation; not the full corpus
3. Index stays small (<50 lines) → negligible context cost on every invocation

---

## Scaling Considerations

This is a local plugin; "scale" means "how many skills before the architecture needs revisiting."

| Skill count | Architecture note |
|-------------|-------------------|
| 1-5 skills (current) | Self-contained SKILL.md files per skill; no shared layer needed |
| 6-15 skills | If 3+ skills share identical interview scaffolding or output patterns, extract to a shared `references/` at repo root, `@`-referenced explicitly |
| 15+ skills | Consider a shared `workflows/` directory mirroring GSD's pattern; each SKILL.md becomes a thin dispatcher referencing the workflow file |

Current scope (3 skills) is firmly in the first tier. Do not build the shared layer now.

---

## Open Questions

- **Naming for skill-create:** Should the slash command be `/skill-create` or `/create-skill` or `/new-skill`? The Anthropic official one is `/skill-creator`. Avoiding ambiguity is important if users have the official plugin installed.
- **docs/ population:** How will the user download Claude Code docs? A one-time manual step? A helper script? This is a prerequisite for skill-create to work and should be addressed in the README or as a setup phase.
- **plugin.json `version` field:** Official examples don't include `version`. Check whether `/plugin update` behavior requires it — may matter for distribution.

---

## Sources

- `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/README.md` — canonical plugin structure, skills/ vs commands/ distinction (HIGH confidence)
- `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/.claude-plugin/plugin.json` — verified plugin.json schema: name, description, author (HIGH confidence)
- `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/example-plugin/skills/example-skill/SKILL.md` — frontmatter fields, model-invoked skill pattern (HIGH confidence)
- `C:/Users/dev/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/SKILL.md` — progressive disclosure, three-tier loading, 500-line guideline, references/ pattern, docs/ on-demand loading (HIGH confidence)
- `C:/Users/dev/.claude/plugins/cache/obsidian-skills/obsidian/1.0.1/README.md` — multi-skill plugin structure, install scopes (HIGH confidence)
- `C:/Users/dev/.claude/plugins/installed_plugins.json` — confirmed plugin cache location; confirmed plugin skills are NOT copied to ~/.claude/skills/ (HIGH confidence, empirical)
- `C:/Users/dev/.claude/skills/gsd-new-project/SKILL.md` — thin-dispatcher pattern with @-referenced workflows (HIGH confidence)
- `C:/Users/dev/.claude/skills/gsd-quick/SKILL.md` — argument parsing, security boundaries, $ARGUMENTS handling (HIGH confidence)
- `C:/Users/dev/.claude/get-shit-done/references/project-skills-discovery.md` — how agents discover and load skills (HIGH confidence)

---
*Architecture research for: Claude Code skills plugin (prompt-improve, skill-create, workspace-create)*
*Researched: 2026-04-26*
