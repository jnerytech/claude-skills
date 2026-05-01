---
name: save-session
description: "Use when the user wants to summarize the current session (what was done, decisions, pending items) and persist it as markdown to .workspace/sessions/[timestamp]-[topic].md, or asks to 'salvar sessão', 'salvar contexto', 'resumir a sessão', 'gerar resumo da sessão', 'pendências'. Redacts secrets before writing — never persists credentials, tokens, or keys to disk. Manual invocation only via /save-session [topic]."
disable-model-invocation: false
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

4. **Redact secrets before writing.** The session file lands on disk and may be committed, shared, or synced. NEVER persist real credentials. Do NOT proceed to step 5 (Write) until every bullet has been scanned and any matched value replaced with a `<REDACTED:kind>` placeholder.

   Scrub every bullet before it goes into the file. For each of these patterns, replace the actual value with a `<REDACTED:kind>` placeholder while keeping the surrounding context (file path, variable name, kind of secret):

   | Pattern | Example replacement |
   |---|---|
   | AWS access keys (`AKIA...`, `ASIA...`, 20 chars) | `<REDACTED:aws-access-key>` |
   | AWS secret keys (40-char base64 next to access key) | `<REDACTED:aws-secret>` |
   | GitLab PATs (`glpat-...`) | `<REDACTED:gitlab-pat>` |
   | GitHub tokens (`ghp_...`, `gho_...`, `ghs_...`, `github_pat_...`) | `<REDACTED:github-token>` |
   | Azure DevOps PATs / Azure AD client secrets | `<REDACTED:azure-secret>` |
   | SonarQube tokens (`squ_...`, `sqp_...`, `sqa_...`) | `<REDACTED:sonarqube-token>` |
   | Slack tokens (`xox[abprs]-...`) | `<REDACTED:slack-token>` |
   | Generic JWTs (`eyJ...` 3-part) | `<REDACTED:jwt>` |
   | Private keys (`-----BEGIN ... PRIVATE KEY-----`) | `<REDACTED:private-key>` |
   | Bearer tokens, API keys, passwords appearing inline | `<REDACTED:secret>` |
   | Database connection strings with embedded password (`postgres://user:pass@...`) | redact only the `pass` segment → `postgres://user:<REDACTED:db-password>@...` |

   Rule of thumb: if a value would let someone authenticate as the user or a service, redact it. Keep the *fact* that the secret was found and *where* — drop the value itself.

   Refuse to write the file if you cannot reliably redact a value (e.g. the user pasted a long opaque blob you cannot classify). Instead, output in chat:

   > Sessão não salva — encontrei um valor que parece sensível mas não consegui classificar com segurança: `<short label>`. Confirme se devo gravar com `<REDACTED:unknown>` ou pular esse bullet.

   Wait for the user's reply before writing.

5. Write the file using the Write tool. Content must follow this structure:

```markdown
# Sessão <YYYY-MM-DD HH:MM> — <Topic human-readable>

## O que foi feito

<Bullet list of concrete actions taken this session — secrets redacted>

## Decisões

<Bullet list of decisions made and their rationale — secrets redacted>

## Pendências

<Bullet list of open questions, next steps, or blocked items — secrets redacted; omit section if none>
```

Keep each bullet tight. No filler. Decisions must include the "why" when non-obvious.

6. **Post-write verification.** Before reporting success, scan the written file for residual secret patterns. Run via Bash:

   ```bash
   grep -nE '(AKIA|ASIA)[0-9A-Z]{16}|glpat-[A-Za-z0-9_-]+|ghp_[A-Za-z0-9]+|squ_[A-Za-z0-9]+|xox[abprs]-[A-Za-z0-9-]+|-----BEGIN[^-]+PRIVATE KEY-----' .workspace/sessions/<timestamp>-<topic>.md || echo "CLEAN"
   ```

   Do NOT report success until grep prints exactly `CLEAN`. If output is anything other than `CLEAN`, delete the file via `rm` and report the leak to the user — NEVER leave a partially-redacted file on disk.

## Critical Rules

- NEVER write the file before step 4 redaction has run on every bullet.
- NEVER report success before step 6 grep prints `CLEAN`.
- If a value cannot be classified safely, MUST refuse and ask the user — do not guess.
- MUST use `mkdir -p` before any Write call. Write tool does NOT create parent dirs.
- Tool boundary: only `Write` and `Bash` are allowed. NEVER use Read or Grep on user files unrelated to the session log.
- Body section names (`O que foi feito`, `Decisões`, `Pendências`) MUST stay PT-BR — they are the persistent template, not control flow.

## Final checks before reporting success

1. `mkdir -p .workspace/sessions` ran before the Write call.
2. Every bullet was scanned for the secret patterns table; matches replaced with `<REDACTED:kind>` placeholders.
3. File written to `.workspace/sessions/<timestamp>-<topic>.md` with the three-section template.
4. Post-write `grep` printed `CLEAN`.
5. If the grep flagged residue, the file was deleted via `rm` and the leak was reported — NO partial file left on disk.
