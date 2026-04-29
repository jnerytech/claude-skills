#!/usr/bin/env bash
# Creates symlinks required for local marketplace plugin registration.
# Run once after cloning: bash setup.sh

set -e

REPO="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$REPO/plugins/claude-skills"

echo "Repo: $REPO"

ln -sf "$REPO/.claude-plugin" "$PLUGIN_DIR/.claude-plugin"
ln -sf "$REPO/skills"         "$PLUGIN_DIR/skills"

echo "Symlinks created:"
ls -la "$PLUGIN_DIR"
echo ""
echo "Next: /plugin marketplace add $REPO"
echo "Then add to ~/.claude/settings.json:"
echo '  "enabledPlugins": { "claude-skills@claude-skills-local": true }'
echo "Then restart Claude Code."
