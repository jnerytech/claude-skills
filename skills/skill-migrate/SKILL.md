---
name: skill-migrate
description: "Migrates a skill, command, prompt, or rule from another AI provider (Cursor, Cline, Continue, Aider, Copilot, OpenAI GPT export, generic prompt) into a Claude Code skill: detects the source format, maps semantics into Claude's frontmatter + body, previews the result, and writes to ~/.claude/skills/<name>/SKILL.md after the user confirms. Manual invocation only via /skill-migrate <path-or-url>."
argument-hint: [path-or-url]
allowed-tools: [Read, Write, Bash, WebFetch, Glob]
disable-model-invocation: true
model: opus
---

# Skill Migrate

The user invoked this with: $ARGUMENTS

## Stage 1 — When to act

If `$ARGUMENTS` is empty or contains only whitespace, output exactly:

> Provide a path or URL to the source artifact, for example:
> `/skill-migrate ./.cursor/rules/api-style.mdc`
> `/skill-migrate ./.cursorrules`
> `/skill-migrate https://example.com/my-gpt.json`

Then stop — do not infer, do not ask a clarifying question.

Otherwise proceed to Stage 2.

## Stage 2 — Read the spec

Before any inference or write, **always** read:

```
${CLAUDE_SKILL_DIR}/references/extend-claude-with-skills.md
```

Mandatory step. Every Claude Code frontmatter field, default, and limit referenced below comes from this doc. Treat it as the authoritative source — if a mapping decision in later stages conflicts with this doc, the doc wins.

The `references/` folder contains three additional docs. Load each only when its trigger fires (see Stage 4.5 — *Conditional reference reads*). Never skip a triggered reference; it carries the rules for the matching capability and the migration must respect them.

## Stage 3 — Resolve the source

`$ARGUMENTS` is one token: a local path, a `file://` URI, or an `http(s)://` URL.

| Form | Action |
|---|---|
| `http://` or `https://` URL | `WebFetch` the URL. Treat the body text as the source content. |
| Local path to a file | `Read` the file. |
| Local path to a directory | `Glob` for known foreign patterns inside it (`.cursorrules`, `*.mdc`, `.clinerules`, `*.md`, `config.json`). If exactly one match, treat as the source. If many, list them and ask the user which to migrate. If none, error and stop. |

Capture both the raw content and the resolved filename/extension for Stage 4.

## Stage 4 — Detect the source format

Pick the first match. Do not ask the user — infer from filename + content shape.

| Heuristic | Format |
|---|---|
| Filename ends in `.mdc` AND content starts with `---` YAML | **Cursor rule (modern)** |
| Filename is `.cursorrules` (no ext) | **Cursor rules (legacy)** |
| Filename is `.clinerules` or path contains `cline` | **Cline rules** |
| Path contains `.continue/` or filename is `config.json` with `prompts` key | **Continue prompt** |
| Filename is `.aider.conf.yml` or path contains `aider` | **Aider config** |
| Path contains `copilot-instructions.md` | **GitHub Copilot instructions** |
| Content is JSON with `name` AND `instructions` keys (OpenAI GPT export shape) | **OpenAI GPT export** |
| Filename ends in `.md` and content is plain markdown prose | **Generic prompt / rule** |
| None of the above | **Generic** — treat content as raw system prompt body |

Record the detected format. State it in the inference summary at Stage 7.

## Stage 4.5 — Conditional reference reads

After detection, scan the foreign source's frontmatter, content, and filename for these cues. Load each triggered reference **before** any mapping decision touches that capability — the doc carries the rules.

| Trigger in foreign source | Reference to read |
|---|---|
| Mentions hooks, file-watchers, git events (`pre-commit`, `on-save`, `post-merge`), or auto-run on tool events | `${CLAUDE_SKILL_DIR}/references/automate-workflows-with-hooks.md` |
| Describes spawning sub-agents, isolated context, role-based delegation, or multi-agent orchestration (common in OpenAI Assistants with `tools: [function]` chains, or Continue's agent prompts) | `${CLAUDE_SKILL_DIR}/references/create-custom-subagents.md` |
| References CI, headless runs, GitHub Actions, scripts that invoke the AI non-interactively, or Aider's `--yes` / scripted modes | `${CLAUDE_SKILL_DIR}/references/run-claude-code-programmatically.md` |
| The mapping plan in Stage 5 will set `context: fork`, an `agent:` field, a `hooks:` field, or override `disable-model-invocation` | read whichever of the three docs covers that field, even if the foreign source did not explicitly mention it |

If no trigger fires, proceed with only the core spec from Stage 2. Do not preload reference docs speculatively — they cost context.

When a reference is loaded, cite it by filename in the inference summary at Stage 7 so the user sees which rules shaped the migration.

## Stage 5 — Map foreign → Claude

Build a mapping table in memory, then generate the SKILL.md in Stage 6.

### Name

Derive in order: explicit `name` field in foreign frontmatter/JSON → filename stem (kebab-cased) → verb-object pair from the description/instructions.

Validate against `^[a-z0-9]+(-[a-z0-9]+)*$`, ≤64 chars. Slugify if needed.

### Description (Claude frontmatter)

| Source format | Source field |
|---|---|
| Cursor `.mdc` | frontmatter `description` |
| Cursor `.cursorrules` | first-line summary, or first sentence of body |
| Cline | first-line summary of body |
| Continue prompt | `description` if present, else `name` blurb |
| OpenAI GPT export | top of `instructions` (first 1–2 sentences) |
| Aider config | "Aider settings imported as Claude skill: <one-line summary>" |
| Copilot instructions | first paragraph |
| Generic | first sentence; if none, "Migrated from <filename>." |

Append manual-invocation phrasing: `Manual invocation only via /<name> [args].` (omit `[args]` if the source has no obvious argument).

### Body

Use the foreign content as the skill body **verbatim** when it is prose. Strip foreign-specific frontmatter (Cursor `.mdc` YAML, Continue JSON wrapper) so only the instructional content remains. Preserve fenced code blocks unchanged. Do not paraphrase user instructions — migration must keep intent intact.

For OpenAI GPT export: use the `instructions` string as the body. List `tools` (web, code_interpreter, file_search) and `knowledge_files` under a `## Notes from source` section so the user knows what could not auto-map.

For Aider config: render the YAML keys as a `## Imported settings` reference list. Aider runtime flags do not map to Claude tools — surface them as documentation, not behavior.

### `allowed-tools` inference

Inspect the body for verb cues:

| Cue in body | Add to `allowed-tools` |
|---|---|
| "write file", "create", "scaffold", "save to" | `Read, Write` |
| "edit", "modify", "patch existing" | add `Edit` |
| "run", "execute", "shell", "command" | add `Bash` |
| "search", "find", "grep", "look up" | add `Glob, Grep` |
| Pure explanation/review with no file output | omit `allowed-tools` (chat-only) |

If ambiguous, default to chat-only. Tools can be added in the confirm step.

### Trigger

Default: **user-only** (`disable-model-invocation: true`).

Override to auto-invoke (omit the flag) only when:
- Cursor `.mdc` frontmatter has `alwaysApply: true`, OR
- Source is reference-only content with no side effects AND no shell/write cues.

### `argument-hint`

Add `[<arg>]` only when the source body references variables like `$ARGUMENTS`, `{input}`, `{{topic}}`, or instructs the user to pass a parameter. Omit otherwise.

### Supporting files

If the source resolved to a directory with multiple foreign files, copy auxiliary files (templates, examples, references) into the new skill directory verbatim under their original names. The body should reference them with relative paths. Skip foreign config-only files (`.aider.conf.yml`, `package.json`).

## Stage 6 — Generate SKILL.md

Frontmatter template:

```yaml
---
name: <inferred name>
description: "<mapped description + manual-invocation phrasing>"
argument-hint: [<hint>] # omit if no $ARGUMENTS use
allowed-tools: [<inferred tools>] # omit if chat-only
disable-model-invocation: true # omit only on documented override
---
```

Body sections, in order:
- `## When to act` — empty-input guard if `argument-hint` is set; otherwise omit
- `## Source` — one line: `Migrated from <format> at <original path or URL>.`
- The mapped body content (verbatim foreign instructional text)
- `## Notes from source` — only if foreign features could not map (GPT tools, Aider flags, Continue model bindings)

Ground every Claude Code frontmatter field name and capability in what was read from `extend-claude-with-skills.md` in Stage 2.

## Stage 7 — Preview and confirm

Check whether the target path already exists:

```bash
test -f "$USERPROFILE/.claude/skills/<name>/SKILL.md" && echo "EXISTS" || echo "NEW"
```

If `EXISTS`, prepend this warning to the preview:

> A skill named `<name>` already exists at $USERPROFILE/.claude/skills/<name>/SKILL.md. Overwrite?

Display the full generated SKILL.md (frontmatter + body) inside a 4-backtick outer fence:

````markdown
---
name: <name>
...
---

[body]
````

Below the preview, output a one-line inference summary and a confirm prompt in chat (not via AskUserQuestion):

> **Migrated from:** `<format>` · **name** `<name>` · **tools** `<tools or "none">` · **trigger** `<user-only or auto>` · **aux files** `<count or "none">` · **refs consulted:** `<comma-separated reference filenames, or "spec only">`
>
> Reply 'yes' to write, or describe changes (e.g. "rename to foo-bar", "add Bash to tools", "make it auto-invocable", "drop the Notes section").

Wait for the user reply. If they describe changes, regenerate Stage 6 with updated settings and show the preview again. Loop until 'yes'.

## Stage 8 — Write the skill

Validate first, mkdir second, Write third. Never reorder.

1. **Validate the name** before any file operation:
   - Matches `^[a-z0-9]+(-[a-z0-9]+)*$`, ≤64 chars
   - Contains no `/`, `..`, or `\`
   If validation fails, output an error and stop — do not run mkdir or Write.

2. **Create the directory** via Bash:
   ```bash
   SKILL_DIR="$USERPROFILE/.claude/skills/<validated-name>"
   mkdir -p "$SKILL_DIR"
   ```
   Use `$USERPROFILE`, not `~` — the Write tool does not expand `~` on Windows (Issue #30553). `$USERPROFILE` is reliably exported in git-bash on Windows.

3. **Write** the generated SKILL.md content to `$SKILL_DIR/SKILL.md`.

4. **Copy auxiliary files** (if any were identified in Stage 5) into `$SKILL_DIR/` using `Read` + `Write`. Preserve original filenames.

## Stage 9 — Confirm

Output in chat:

> Migrated `<original source>` → `$USERPROFILE/.claude/skills/<name>/SKILL.md`<br>
> `<aux file count>` auxiliary files copied.<br>
> Restart Claude Code to load the skill.

## Worked example — Cursor `.mdc` rule

User runs `/skill-migrate ./.cursor/rules/api-style.mdc`.

- **Stage 1:** non-empty → proceed.
- **Stage 2:** read spec.
- **Stage 3:** `Read` the file. Source content:
  ```
  ---
  description: "Enforce REST API conventions"
  globs: ["src/api/**/*.ts"]
  alwaysApply: true
  ---
  All endpoints must use kebab-case paths. Return 4xx with a JSON `error` field.
  ```
- **Stage 4:** filename `.mdc` + YAML frontmatter → **Cursor rule (modern)**.
- **Stage 5:** map:
  - name: `api-style` (filename stem)
  - description: `"Enforce REST API conventions. Manual invocation only via /api-style."`
  - body: prose after frontmatter, verbatim
  - allowed-tools: omitted (chat-only — no write/run cues)
  - trigger: `alwaysApply: true` → auto-invoke (omit `disable-model-invocation`)
  - argument-hint: omit
- **Stage 6:** generate.
- **Stage 7:** preview, summary `Migrated from: Cursor rule (modern) · name api-style · tools none · trigger auto · aux files none`. User replies `yes`.
- **Stage 8:** validate `api-style`, mkdir, write.
- **Stage 9:** confirm.

## Worked example — OpenAI GPT JSON export

User runs `/skill-migrate ./my-export.json`.

- **Stage 4:** JSON with `name` + `instructions` → **OpenAI GPT export**.
- **Stage 5:**
  - name: slugified `name` field
  - description: first sentence of `instructions` + manual-invocation phrasing
  - body: `instructions` verbatim
  - `## Notes from source`: list `tools: [web, code_interpreter]` and `knowledge_files: [...]` since neither maps to Claude tools
  - allowed-tools: chat-only unless instructions mention shell/write
  - trigger: user-only (default)
- Continue normally through Stages 6–9.

## Final checks before writing

Before executing the write step (Stage 8), confirm:

1. Spec (`extend-claude-with-skills.md`) was read in Stage 2 before any mapping.
2. Source format was detected (Stage 4) and stated in the inference summary.
3. Conditional refs (Stage 4.5) were loaded for every fired trigger and listed in the inference summary.
4. Name was inferred and validated (`^[a-z0-9]+(-[a-z0-9]+)*$`, no `/`, `..`, or `\`).
5. Body content was preserved verbatim from the source; foreign frontmatter stripped, prose unchanged.
6. Generated SKILL.md was shown in a 4-backtick fenced preview before writing.
7. Inference summary listed source format, name, tools, trigger, aux file count, and refs consulted.
8. User confirmed with "yes" or equivalent in chat.
9. `mkdir -p` ran before the Write call.
10. `$USERPROFILE` was used — not `~`.
