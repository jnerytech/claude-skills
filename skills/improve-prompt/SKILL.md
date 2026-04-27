---
name: improve-prompt
description: "Rewrites a rough prompt for clarity, specificity, context richness, and structure. Use when the user invokes /improve-prompt or asks to 'improve this prompt', 'rewrite this prompt', or 'make this prompt clearer'. Do NOT use for general writing improvements unrelated to Claude Code prompts."
argument-hint: <rough-prompt-text>
disable-model-invocation: true
---

# Improve Prompt

The user invoked this with: $ARGUMENTS

<!-- Phase 2 will fill in the full rewrite instructions here. -->
<!-- Constraints to honor:
  - Output improved prompt + "what changed" annotation
  - Apply 4 dimensions: clarity/specificity, context richness, structure, scope/verification criteria
  - Inject Claude Code-specific idioms (@file references, verification asks, scope bounds)
  - Show original and improved prompt side by side
  - AskUserQuestion: max 4 options per call
-->
