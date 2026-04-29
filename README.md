# Claude Code Skills Plugin

Four Claude Code slash-command skills that improve day-to-day workflow.

## What It Does

- `/improve-prompt <rough-prompt>` — rewrites a rough prompt for clarity, specificity, context richness, and structure
- `/skill-create [skill-description]` — interviews you, reads local docs, and generates a new skill written globally to `~/.claude/skills/`
- `/workspace-create` — guided interview that scaffolds a full workspace with a populated CLAUDE.md
- `/save-session [topic]` — summarizes the current session and saves it to `.workspace/sessions/`

## Getting Started

**Prerequisites:** Claude Code installed and running.

1. Clone this repo:
   ```
   git clone https://github.com/<your-username>/claude-skills <local-path>
   ```

2. Install the plugin:
   ```
   /plugin install <local-path>
   ```

3. Copy the permissions template:
   ```
   cp settings.local.json.example settings.local.json
   ```
   This grants the skills the file-write permissions they need (workaround for v2.1.79+ regression).

The plugin's four skills are now available as slash commands: `/improve-prompt`, `/skill-create`, `/workspace-create`, `/save-session`.

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
