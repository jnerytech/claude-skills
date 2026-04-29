---
status: testing
phase: 04-workspace-creator-skill
source: [04-01-SUMMARY.md]
started: 2026-04-29T00:00:00Z
updated: 2026-04-29T00:00:00Z
---

## Current Test

number: 1
name: No-arg invocation starts interview
expected: |
  Invoke `/workspace-create` with no arguments. Skill asks for workspace
  name in chat (Q1) — no AskUserQuestion, plain chat prompt. No files
  are created yet.
awaiting: user response

## Tests

### 1. No-arg invocation starts interview
expected: Invoke `/workspace-create` with no arguments. Skill asks for workspace name in chat (Q1) — plain chat prompt, no AskUserQuestion call. No files are created yet.
result: [pending]

### 2. Argument hint skips to repos
expected: Invoke `/workspace-create my-apis`. Skill accepts "my-apis" as workspace name from $ARGUMENTS, skips Q1, and goes straight to Q2 (asking which repos to include).
result: [pending]

### 3. Name validation rejects invalid input
expected: At Q1, enter an invalid name (e.g. "My Workspace" with spaces or "123bad" starting with digit). Skill outputs an error and re-asks for the name — does not proceed.
result: [pending]

### 4. Interview covers all 5 questions
expected: Go through full interview: Q1 workspace name, Q2 list of repos, Q3 per-repo purpose, Q4 overall goal, Q5 tech stack. All answers accepted via plain chat — no AskUserQuestion calls (freeform answers, variable length).
result: [pending]

### 5. Scaffold plan preview before any writes
expected: After Q5, skill displays a 4-backtick-fenced plan preview listing directories and files to be created. Interview answers are reflected in the preview. Skill asks for confirmation in chat before creating anything.
result: [pending]

### 6. Directory structure created correctly
expected: After confirming, these directories exist under the workspace root: `.workspace/refs/`, `.workspace/docs/`, `.workspace/logs/`, `.workspace/scratch/`, `.workspace/context/`, `.workspace/outputs/`, `.workspace/sessions/`, `.claude/`, `.vscode/`.
result: [pending]

### 7. READMEs in each .workspace/ subdir
expected: Each of the 7 `.workspace/` subdirectories contains a `README.md` with a one-line description of that directory's purpose.
result: [pending]

### 8. CLAUDE.md fully populated, no unreplaced markers
expected: `CLAUDE.md` exists at workspace root. Running `grep '{{' CLAUDE.md` returns nothing (zero unreplaced markers). Workspace name, goal, date, repo map, and stack from interview answers appear in the file.
result: [pending]

### 9. .claude/settings.local.json created
expected: `.claude/settings.local.json` exists at workspace root with permission allow rules populated.
result: [pending]

## Summary

total: 9
passed: 0
issues: 0
pending: 9
skipped: 0
blocked: 0

## Gaps

