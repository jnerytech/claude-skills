---
name: save-session
description: Summarize the current session and save to .workspace/sessions/. Use when closing a session, wrapping up work, or when user says "salva a sessão", "save session", "resumo da sessão", or invokes /save-session.
disable-model-invocation: true
allowed-tools: Write
argument-hint: "[topic]"
---

## Context

- Timestamp: !`date +%Y-%m-%d-%H-%M`
- Workspace sessions dir: `.workspace/sessions/`

## Your task

1. Derive a short kebab-case topic slug from `$ARGUMENTS` (if provided) or from the main subject of this session (2-4 words max).

2. Build the output filename:
   ```
   .workspace/sessions/<timestamp>-<topic>.md
   ```
   where `<timestamp>` is the value from the Context block above (format: `YYYY-MM-DD-HH-MM`).

3. Write the file using the Write tool. Content must follow this structure:

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
