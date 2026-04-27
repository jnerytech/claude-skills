---
name: workspace-create
description: "Guides a workspace setup interview and scaffolds .workspace/, .claude/, .vscode/ directories with a fully populated CLAUDE.md. Use when the user invokes /workspace-create or asks to 'set up a workspace', 'create a workspace', or 'scaffold a new workspace'. Do NOT use for setting up individual project repos."
allowed-tools: [Write, Bash]
disable-model-invocation: true
---

# Workspace Create

<!-- Phase 4 will fill in the full interview and scaffolding instructions here. -->
<!-- Constraints to honor:
  - AskUserQuestion: max 4 options per call — open-ended text for repo names and purpose
  - Interview captures: workspace name, repos list, per-repo purpose, overall workspace goal, conventions
  - Scaffold: .workspace/refs/, docs/, logs/, scratch/, context/, outputs/, sessions/
  - Also create: .claude/ and .vscode/ at workspace root
  - Write README.md in each .workspace/ subdir explaining its purpose
  - Load ${CLAUDE_SKILL_DIR}/templates/CLAUDE.md.template and populate from interview answers
  - CLAUDE.md must have zero stubs — use actual interview answers in every section
  - Validate workspace name: no spaces or special chars (becomes a directory name)
  - Confirm full scaffold with user before writing
  - All paths use forward slashes; do NOT hardcode user home paths
  - CLAUDE.md must be under 200 lines
-->
