# Claude Code Docs Index

This folder holds pre-downloaded Claude Code documentation. `/skill-create` reads it offline — no network calls at invocation time.

Before using `/skill-create`, download the files listed below and place them at the paths shown. The skill reads only the files relevant to your request — not the entire corpus.

## Setup

1. Create the subdirectories:
   ```
   mkdir -p docs/skills docs/commands docs/plugins docs/tools docs/memory
   ```

2. For each row in the table below, visit the Source URL and save the page content as a Markdown file at the File path shown.

## Topic Index

| Topic | File | Source URL | Summary |
|-------|------|------------|---------|
| Skills overview | `skills/overview.md` | https://code.claude.com/docs/en/skills | What skills are, model-invoked vs user-invoked, live reload |
| Skill frontmatter fields | `skills/frontmatter.md` | https://code.claude.com/docs/en/skills | name, description, allowed-tools, argument-hint, disable-model-invocation |
| Skill directory anatomy | `skills/anatomy.md` | https://code.claude.com/docs/en/skills | SKILL.md + references/ + scripts/ + assets/ structure |
| Writing effective descriptions | `skills/writing-guide.md` | https://code.claude.com/docs/en/skills | Trigger phrases, third-person format, Do NOT use for clauses |
| Slash commands and skills | `commands/slash-commands.md` | https://code.claude.com/docs/en/slash-commands | User-invoked skills, $ARGUMENTS, argument-hint |
| Plugin structure | `plugins/structure.md` | https://code.claude.com/docs/en/plugins | plugin.json, skills/ vs commands/ vs agents/ layout |
| Plugin publishing | `plugins/publishing.md` | https://code.claude.com/docs/en/plugins | Marketplace submission, install scopes |
| Tools reference | `tools/tools-reference.md` | https://code.claude.com/docs/en/tools-reference | Available tools, permission requirements, AskUserQuestion |
| Memory and CLAUDE.md | `memory/memory.md` | https://code.claude.com/docs/en/memory | CLAUDE.md scope, directory layout, skills vs CLAUDE.md |

## How to Download

Each documentation page is a single web page. Save the page content as a Markdown file to the path shown in the File column above.

Example: Save https://code.claude.com/docs/en/skills as `docs/skills/overview.md`.

**Important:** Create the subdirectories (`docs/skills/`, `docs/commands/`, `docs/plugins/`, `docs/tools/`, `docs/memory/`) before saving files into them.

## How skill-create Uses This Index

When you invoke `/skill-create`, it reads this file first to find which documentation is relevant to your skill request, then loads only the matching file(s). This keeps context usage low — the entire docs corpus is not loaded on every invocation.
