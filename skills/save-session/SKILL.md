---
name: save-session
description: "Summarizes the current session (what was done, decisions, pendências) and writes a markdown file to .workspace/sessions/<timestamp>-<topic>.md. Manual invocation only via /save-session [topic]."
disable-model-invocation: true
allowed-tools: [Write, Bash]
argument-hint: "[topic]"
model: haiku
---

## Context

- Timestamp: !`date +%Y-%m-%d-%H-%M`
- Workspace sessions dir: `.workspace/sessions/`

## Your task

1. Derive a short kebab-case topic slug from `$ARGUMENTS` (if provided) or from the main subject of this session (2-4 words max).

2. Ensure the target directory exists. Run via Bash before any Write call:
   ```bash
   mkdir -p .workspace/sessions
   ```
   `mkdir -p` is idempotent — it creates `.workspace/` and `.workspace/sessions/` if missing, and is a no-op if they already exist.

3. Build the output filename:
   ```
   .workspace/sessions/<timestamp>-<topic>.md
   ```
   where `<timestamp>` is the value from the Context block above (format: `YYYY-MM-DD-HH-MM`).

4. Write the file using the Write tool. Content must follow this structure:

```markdown
# Sessão <YYYY-MM-DD HH:MM> — <Topic human-readable>

## O que foi feito

<Bullet list of concrete actions taken this session>

## Decisões

<Bullet list of decisions made and their rationale>

## Pendências

<Bullet list of open questions, next steps, or blocked items — omit section if none>
```

Keep each bullet tight. No filler. Decisions must include the "why" when non-obvious.
