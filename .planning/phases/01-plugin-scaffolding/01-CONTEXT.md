# Phase 1: Plugin Scaffolding - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Stand up the repo skeleton so skill development can begin in Phase 2. Deliverables:
plugin manifest, skill stub directories, docs index, install instructions, and
permissions template. No skills are functional at end of Phase 1 — structure only.

</domain>

<decisions>
## Implementation Decisions

### Install Delivery (SETUP-04)
- **D-01:** Install mechanism is `/plugin install <local-repo-path>` — Claude Code's
  native plugin install command. No helper script needed.
- **D-02:** Install instructions live in `README.md` in a "Getting Started" section.
  One focused section: prerequisites, clone, then `/plugin install` command.

### Permissions Template (SETUP-05)
- **D-03:** Template committed as `settings.local.json.example` — safe to commit
  publicly, clearly marked as a template. Users copy and rename to `settings.local.json`.
- **D-04:** Template scope is extended — include all four allows that downstream skills
  will need:
  - `Write(.claude/**)`
  - `Write(~/.claude/**)`
  - `Bash(mkdir:**)`
  - `Bash(cp:**)`
  Rationale: workspace-create scaffolds directories and copies templates; include these
  now so users don't hit permission errors in Phases 3–4.

### Skill Format (locked from research)
- **D-05:** YAML frontmatter + Markdown body — NOT XML `<skill>` tags. This is the
  verified format from reading installed plugin sources.

### Windows Paths (locked from research)
- **D-06:** All path references in SKILL.md bodies use `$USERPROFILE`, not `~`.
  Relevant to skill-create and workspace-create write paths.

### Claude's Discretion
- Placeholder SKILL.md content depth — bare frontmatter stub is sufficient for Phase 1;
  section headings and body content come in Phases 2–4.
- `docs/index.md` internal format — topic table vs checklist vs annotated tree; planner
  and researcher should design for readability by skill-create at runtime.
- AskUserQuestion hard limit (4 options max) is a constraint, not a Phase 1 deliverable —
  note it in the skill stubs or a constraints doc so Phase 2–4 authors see it.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Roadmap
- `.planning/REQUIREMENTS.md` — SETUP-01 through SETUP-05 define all Phase 1 acceptance criteria
- `.planning/ROADMAP.md` — Phase 1 success criteria (5 numbered items under Plugin Scaffolding)
- `.planning/PROJECT.md` — Core constraints: skill format, docs folder read-only at runtime,
  Windows path requirement (`$USERPROFILE`), AskUserQuestion 4-option limit

### Architecture Research
- `.planning/research/` — Architecture research files establishing plugin structure,
  component responsibilities, and recommended project layout. High-confidence findings
  from reading installed plugin sources. Planner MUST read before creating file list.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — fresh repo. Only `CLAUDE.md` exists at root.

### Established Patterns
- Plugin manifest location: `.claude-plugin/plugin.json` (from research — verified against
  installed plugin corpus)
- Skill file location: `skills/<name>/SKILL.md` (one file per skill, YAML frontmatter + body)
- Docs index convention: `docs/index.md` as entry point; skill-create reads it first, then
  loads specific topic files on demand

### Integration Points
- Phase 2 starts writing `skills/improve-prompt/SKILL.md` — stub must exist with valid
  frontmatter so Phase 2 can edit rather than create
- Phase 3 needs `skills/skill-create/references/` directory to exist for its supporting docs
- Phase 4 needs `skills/workspace-create/templates/` directory to exist for its CLAUDE.md template

</code_context>

<specifics>
## Specific Ideas

No specific implementation references surfaced during discussion — standard approaches apply.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-Plugin Scaffolding*
*Context gathered: 2026-04-26*
