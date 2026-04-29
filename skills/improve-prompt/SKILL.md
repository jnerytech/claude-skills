---
name: improve-prompt
description: "Rewrites a rough prompt for clarity, specificity, context richness, and structure. Outputs three sections (Original / Improved / What Changed) and injects Claude Code idioms (@file, verification, scope bounds) only when cued. Manual invocation only via /improve-prompt <rough-prompt>."
argument-hint: [rough-prompt-text]
disable-model-invocation: true
model: haiku
---

# Improve Prompt

The user invoked this with: $ARGUMENTS

## When to act

If `$ARGUMENTS` is empty or contains only whitespace, output exactly:

> Provide the rough prompt you want improved as an argument, for example:
> `/improve-prompt fix the auth bug`

Then stop — do not attempt a rewrite, do not ask a clarifying question.

Otherwise, treat everything in `$ARGUMENTS` as the rough prompt the user wants rewritten, and proceed.

## How to rewrite

Apply these four dimensions to the rough prompt. Each definition is a concrete action verb — apply only the dimensions that need work, not all four mechanically:

- **Clarity / specificity** — Name the exact file, function, or behavior involved. Replace pronouns like "it" or "that" with concrete nouns.
- **Context richness** — Add an `@file` reference when a file is mentioned or implied. Add the relevant constraint (language, framework, version) when known.
- **Structure** — Open with an imperative verb. Separate "what to do" from "how to verify" into distinct sentences or a small numbered list.
- **Scope / verification** — State what Claude should NOT change. Specify how to confirm the task is done (a test command, a behavior to observe, an acceptance check).

When rewriting the Improved section, render the user's task in your own clearer words — but never lose the user's intent. The Original section, by contrast, is the user's input verbatim (see "How to format output" below).

## Inject Claude Code idioms — only on cue

Apply these idioms only when their cue is present in the rough prompt. Do not add them indiscriminately:

| Idiom | Inject when | Example |
|-------|-------------|---------|
| `@file <path>` | A filename, path, or module name is mentioned or clearly implied (e.g. "the auth middleware") | `@file src/auth/middleware.ts` |
| Verification ask | The task verb is fix, refactor, implement, migrate, add, update, or another code-change verb | "Run `npm test -- auth` to verify no regressions" |
| Scope bounds | The prompt has no clear success criteria, or could be interpreted too broadly | "Focus only on the token expiry check; do not refactor the surrounding handler" |

When a filename is implied but not stated (e.g. the user says "auth middleware"), infer a plausible `@file` path rather than omitting the reference. A concrete-but-approximate reference like `@file auth/middleware.ts` is more useful than no reference, because Claude at invocation time will correct wrong guesses.

## Handle low-information input

If the rough prompt is too vague to rewrite with full specificity (it is short, names no file, and describes no scope), produce the best rewrite you can using bracketed placeholders to mark structurally missing context. Examples of placeholders: `[describe symptom]`, `[specify the target file]`, `[expected vs actual behavior]`.

Do not ask a clarifying question first — the user invoked `/improve-prompt` for a fast turnaround. Always produce a rewrite.

When (and only when) the input was detectably low-information — short, no file references, no describable scope — append a sharpen note after `## What Changed`:

> ⚠️ To sharpen further, add: [comma-separated list of context items that would improve the rewrite]

Do not add this note to already-decent prompts. Signal-to-noise matters.

## How to format output

Output exactly three `##` sections in this order. Render both prompts inside triple-backtick fenced code blocks so the user can copy them. The `## What Changed` section is a bullet list, never a paragraph.

````
## Original
```
[the user's rough prompt — verbatim, unchanged, do not "lightly clean up" the wording]
```

## Improved
```
[the rewritten prompt]
```

## What Changed
- [Change label] — [one-sentence reason why it improves the prompt]
- [Change label] — [one-sentence reason]
````

Each bullet in `## What Changed` follows the pattern `- [Change label] — [one-sentence reason why it improves the prompt]`.

Only emit a bullet for a change you actually made. If a dimension was already strong in the original, omit its bullet — the goal is signal density, not exhaustive coverage. The "most impactful change first" ordering is preferred but not enforced.

If the input was low-information, append the `⚠️ To sharpen further, add:` note on its own line below the bullet list.

## Worked example — desired output for a code-change prompt

When the user runs `/improve-prompt fix the auth bug`, your output should look like this:

````markdown
## Original
```
fix the auth bug
```

## Improved
```
In auth/middleware.ts, the token expiry check uses `<` instead of `<=`. Fix it and run `npm test -- auth` to verify no regressions.
```

## What Changed
- Added @file reference — gives Claude a precise entry point instead of searching the whole codebase
- Added scope: narrowed to token expiry logic — prevents Claude from refactoring unrelated code
- Added verification step — gives Claude a way to confirm its fix worked without being asked
````

(The 4-backtick fence above is only how this example is encoded inside SKILL.md so the inner triple-backticks render correctly. Your actual chat output uses triple-backtick fences as shown in the "How to format output" section.)

## Worked example — desired output for a low-information prompt

When the user runs `/improve-prompt fix it`, your output should look like this:

````markdown
## Original
```
fix it
```

## Improved
```
Identify and fix the bug in [specify the target file] causing [describe symptom]. After fixing, run the relevant tests to confirm the regression is resolved.
```

## What Changed
- Added symptom placeholder — Claude needs to know what is broken to find the right bug
- Added verification step — gives Claude a way to confirm the fix worked

⚠️ To sharpen further, add: which file or feature is affected, and what the expected vs actual behavior is.
````

## Final checks before responding

Before sending output, confirm:
1. Three `##` sections are present in this exact order: Original, Improved, What Changed.
2. The Original section contains the user's input verbatim, inside a fenced code block.
3. The Improved section contains the rewrite, inside a fenced code block.
4. Every bullet under `## What Changed` matches `- [Label] — [reason]`.
5. Idioms (`@file`, verification, scope bounds) only appear if their cue was present.
6. The sharpen note appears only if the input was detectably low-information.
7. No file was written; no tool was invoked. The output is chat-only.
