# Claude Code Skills Plugin

## Project

Three Claude Code slash-command skills packaged as a plugin:
- `/improve-prompt` — rewrites rough prompts for clarity, context, structure, scope
- `/skill-create` — interviews user, reads local docs/, generates skill to `~/.claude/skills/`
- `/workspace-create` — guided interview → scaffolds `.workspace/` + populated CLAUDE.md

See `.planning/PROJECT.md` for full context.

## GSD Workflow

This project uses GSD for planning and execution.

**Current state:** `.planning/STATE.md`
**Roadmap:** `.planning/ROADMAP.md`
**Requirements:** `.planning/REQUIREMENTS.md`

**Phase commands:**
```
/gsd-discuss-phase <N>   — gather context before planning
/gsd-plan-phase <N>      — create execution plan
/gsd-execute-phase <N>   — execute plans
/gsd-verify-work         — verify phase deliverables
```

**Never skip planning.** Each phase needs a plan before execution.

## Key Constraints

- Skill format: YAML frontmatter + Markdown body in `skills/<name>/SKILL.md` — no XML tags
- Plugin manifest: `.claude-plugin/plugin.json` with `name`, `description`, `author`
- `AskUserQuestion` hard limit: 4 options per question — design all interview banks accordingly
- Global skill write path: `~/.claude/skills/<name>/SKILL.md` — use `$USERPROFILE` on Windows, not `~`
- Permission regression v2.1.79+: `Write(~/.claude/**)` must be in `settings.local.json` allow list
- `docs/` folder is read-only at runtime — `skill-create` reads it, never writes to it
- CLAUDE.md output from workspace-create must be under 200 lines

## Build Order

Phase 1 (scaffolding) → Phase 2 (improve-prompt) → Phase 3 (skill-create) → Phase 4 (workspace-create)

Each phase is independently verifiable before the next begins.
