---
name: skill-create
description: "Interviews the user and generates a new Claude Code skill (SKILL.md), then writes it to ~/.claude/skills/<name>/SKILL.md. Use when the user invokes /skill-create or asks to 'create a skill', 'make a new skill', or 'build a slash command'. Do NOT use for general task automation unrelated to skill authoring."
argument-hint: [skill-description]
allowed-tools: [Read, Glob, Grep, Write, Bash]
disable-model-invocation: true
---

# Skill Create

<!-- Phase 3 will fill in the full interview and generation instructions here. -->
<!-- Constraints to honor:
  - Read ${CLAUDE_SKILL_DIR}/docs/ before generating (docs/index.md first, then specific files)
  - Interview with 5-6 targeted questions; propose answers for user to react to
  - AskUserQuestion: max 4 options per call — design all question banks around this hard limit
  - Show generated SKILL.md for review before writing
  - Write to $USERPROFILE/.claude/skills/<name>/SKILL.md (Windows path — D-06)
  - Validate: skill name is kebab-case, no path traversal chars (/, .., \)
  - Confirm with user before writing
-->
