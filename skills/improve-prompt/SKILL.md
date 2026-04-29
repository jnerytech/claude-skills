---
name: improve-prompt
description: "Rewrites a rough prompt for clarity, specificity, context richness, and structure. Scans the codebase (Glob/Grep) to fill in concrete file paths and symbols when the rough prompt only implies them. Outputs just the improved prompt — no Original / What Changed sections. Manual invocation only via /improve-prompt <rough-prompt>."
argument-hint: [rough-prompt-text]
allowed-tools: [Read, Glob, Grep]
disable-model-invocation: true
model: haiku
---

# Improve Prompt

The user invoked this with: $ARGUMENTS

## Stage 1 — When to act

If `$ARGUMENTS` is empty or contains only whitespace, output exactly:

> Provide the rough prompt you want improved as an argument, for example:
> `/improve-prompt fix the auth bug`

Then stop — do not attempt a rewrite, do not ask a clarifying question.

Otherwise, treat everything in `$ARGUMENTS` as the rough prompt and proceed.

## Stage 2 — Detect context cues

Skim the rough prompt for cues that imply concrete code references but don't name them. Each cue triggers a scan in Stage 3:

| Cue in prompt | What to resolve |
|---|---|
| "the X middleware", "the X handler", "the X module" | actual file path of the named module |
| "the auth flow", "the login flow", "the db layer" | files implementing that subsystem |
| "database credentials", "API keys", "secrets" | files with connection strings, `process.env.*`, config loaders |
| "the bug in <feature>" with no file named | likely owner files of that feature |
| "the code", "this codebase", "the app" with no specifics | top-level entry points and config |
| Verb-only ("fix it", "refactor", "update") with no target | abort scan — placeholder route only |

If no cue is present, skip Stage 3 entirely and go to Stage 4.

## Stage 3 — Scan the codebase

Run **at most 4 targeted operations** total — Glob and Grep combined. Do not load whole files; read only when a Glob/Grep hit needs disambiguation.

Patterns by cue type:

- **Module name** (e.g. "auth middleware") → `Glob "**/auth*.{ts,js,py,go,rs,rb}"` and `Glob "**/*middleware*.{ts,js,py,go,rs,rb}"`
- **Subsystem flow** (e.g. "login flow") → `Grep "login\|signIn\|authenticate"` with `output_mode: files_with_matches`
- **Database/secrets** → `Grep "DATABASE_URL\|DB_HOST\|process\.env\|os\.environ\.get\|connection_string"` plus `Glob "**/{db,database,connection,config,env}*.{ts,js,py,go,yaml,yml,json}"`
- **Generic "the codebase"** → `Glob "{package.json,pyproject.toml,Cargo.toml,go.mod,*.csproj}"` for stack identification

Stop early when:
- 1-3 strong candidate files surface — that is enough to substitute placeholders
- The repo appears empty or scans return nothing relevant — fall back to placeholders
- 4 operations have run regardless of result

Record the resolved paths/symbols for Stage 4.

## Stage 4 — Rewrite using the 4 dimensions

Apply these four dimensions only where the rough prompt is weak. Do not mechanically apply all four:

- **Clarity / specificity** — Name the exact file, function, or behavior. Replace pronouns ("it", "that") with concrete nouns.
- **Context richness** — Inject `@file <path>` when Stage 3 resolved a path. If a stack constraint (language, framework, version) is detectable from scan results (e.g. `package.json` showed Next.js), include it.
- **Structure** — Open with an imperative verb. Separate "what to do" from "how to verify" into distinct sentences or a short list.
- **Scope / verification** — State what Claude should NOT change. Specify how to confirm the task is done (test command, observable behavior, acceptance check).

When Stage 3 resolved paths or symbols, substitute them directly — drop the `[placeholder]`. When Stage 3 did not resolve a piece of context, leave a tight bracketed placeholder (e.g. `[describe symptom]`).

Render the user's task in clearer words but never lose the user's intent.

## Stage 5 — Output

Output **only** the improved prompt inside a single triple-backtick fenced code block. Do not emit `## Original`, `## What Changed`, or any other heading. Do not narrate what you scanned.

Example output:

```
[the rewritten prompt — single code block, copy-paste ready]
```

If any bracketed placeholders remain in the rewrite (Stage 3 could not resolve them), append exactly one line below the fenced block:

> ⚠️ To sharpen further, add: [comma-separated list of context items that would resolve the remaining placeholders]

Do not add the sharpen note when every placeholder was resolved by the scan.

## Worked example — code-change prompt with scan

User runs `/improve-prompt fix the auth bug`.

- Stage 2 detects the "auth" subsystem cue.
- Stage 3 runs `Glob "**/auth*.{ts,js,py,go,rs,rb}"` → `src/auth/middleware.ts`, `src/auth/login.ts`. Then `Grep "expir"` in those files → hit on `middleware.ts:47` (`if (token.exp < Date.now())`).
- Stage 4 rewrites with concrete file + line.
- Stage 5 output:

```
In @file src/auth/middleware.ts (line 47), the token expiry check uses `<` instead of `<=`. Fix that comparison and run `npm test -- auth` to verify no regressions. Do not refactor the surrounding handler.
```

## Worked example — vague prompt, scan finds nothing

User runs `/improve-prompt fix it`.

- Stage 2 detects verb-only cue → skip Stage 3 entirely.
- Stage 4 rewrites with placeholders for missing context.
- Stage 5 output:

```
Identify and fix the bug in [specify the target file] causing [describe symptom]. After fixing, run the relevant tests to confirm the regression is resolved.
```

> ⚠️ To sharpen further, add: which file or feature is affected, and what the expected vs actual behavior is.

## Worked example — database/secrets prompt with scan

User runs `/improve-prompt coferir se o codigo usa dados de banco e url host no banco e no codigo`.

- Stage 2 detects database/secrets cue.
- Stage 3 runs `Glob "**/{db,database,connection,config,env}*.{ts,js,py,go,yaml,yml,json}"` → `src/db/client.ts`, `config/database.yml`. Then `Grep "DATABASE_URL\|DB_HOST\|process\.env"` → hits in those two files.
- Stage 5 output:

```
Audit @file src/db/client.ts and @file config/database.yml to verify that database credentials and host URLs are not hardcoded in the application code. Confirm each connection value reads from `process.env.*` (or the documented secrets manager) — flag any string literal that bypasses the env layer. Document each violation with file:line and the remediation path.
```

## Final checks before responding

1. Output is exactly one fenced code block containing only the rewritten prompt — no Original section, no What Changed bullets.
2. Stage 3 ran ≤4 Glob/Grep operations total when cues were present.
3. Resolved paths from Stage 3 appear inline in the rewrite (as `@file <path>` or directly named) — no stray `[target file]` placeholders left over a successful scan.
4. The sharpen note appears only when placeholders remain unresolved.
5. No file was written; no Bash command was run.
