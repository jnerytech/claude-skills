# Claude Code Skills Plugin

Four Claude Code slash-command skills that improve day-to-day workflow.

## What It Does

- `/improve-prompt <rough-prompt>` — rewrites a rough prompt for clarity, specificity, context richness, and structure
- `/skill-create [skill-description]` — interviews you, reads local docs, and generates a new skill written globally to `~/.claude/skills/`
- `/workspace-create` — guided interview that scaffolds a full workspace with a populated CLAUDE.md
- `/save-session [topic]` — summarizes the current session and saves it to `.workspace/sessions/`

## Getting Started

**Prerequisites:** Claude Code installed and running.

### 1. Clone the repo

```bash
git clone https://github.com/jnerytech/claude-skills ~/repos/claude-skills
```

### 2. Copy skills

**Global — available in all projects:**
```bash
mkdir -p ~/.claude/skills
cp -r ~/repos/claude-skills/skills/* ~/.claude/skills/
```

**Project-local — available only in the current project:**
```bash
mkdir -p .claude/skills
cp -r ~/repos/claude-skills/skills/* .claude/skills/
```

### 3. Reload

Run `/reload-plugins` inside Claude Code. The four slash commands are now available.

### 4. Copy the permissions template (if using file-writing skills)

```bash
cp ~/repos/claude-skills/settings.local.json.example .claude/settings.local.json
```

Required for `/skill-create` and `/workspace-create` to write files (workaround for v2.1.79+ permission regression).

### Updating

```bash
cd ~/repos/claude-skills && git pull
cp -r skills/* ~/.claude/skills/   # or project-local path
```

Then `/reload-plugins`.

> **Note:** `/plugin install <local-path>` is marketplace-only and does not work with local directories.

## Skills

### /improve-prompt

Rewrites a rough prompt optimizing for four dimensions: clarity/specificity, context richness, structure, and scope/verification criteria. Outputs original and improved prompts side by side with a "what changed" annotation.

**Usage:** `/improve-prompt <rough-prompt-text>`

### /skill-create

Interviews you about the skill you want to build, reads locally pre-downloaded Claude Code documentation, then generates a SKILL.md file and writes it to `~/.claude/skills/<name>/SKILL.md`.

**Usage:** `/skill-create [optional skill description]`

### /workspace-create

Guides you through a workspace setup interview (name, repos, purposes, goals), then scaffolds a complete workspace structure with a fully populated CLAUDE.md.

**Usage:** `/workspace-create`

### /save-session

Summarizes the current session (what was done, decisions made, open items) and writes it to `.workspace/sessions/<timestamp>-<topic>.md`. Trigger with `/save-session`, "save session", or "salva a sessão".

**Usage:** `/save-session [optional-topic]`

## Docs Setup

Before using `/skill-create`, download the Claude Code documentation files listed in `docs/index.md` into the `docs/` folder. The skill reads these offline — no network calls at invocation time.

## Authors

- jnery.tech (jnery.tech@gmail.com)
