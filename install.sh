#!/usr/bin/env bash
# Install claude-skills into ~/.claude/skills (global) or a custom path.
#
# Global:
#   bash <(curl -fsSL https://raw.githubusercontent.com/jnerytech/claude-skills/master/install.sh)
#
# Project-local (run from project root):
#   bash <(curl -fsSL https://raw.githubusercontent.com/jnerytech/claude-skills/master/install.sh) "$(pwd)"

set -e

DEST="${1:-$HOME/.claude/skills}"
TMP=$(mktemp -d)

echo "Installing claude-skills to: $DEST"

git clone --depth=1 --filter=blob:none --sparse https://github.com/jnerytech/claude-skills "$TMP" -q
git -C "$TMP" sparse-checkout set skills
git -C "$TMP" checkout -q
mkdir -p "$DEST"
cp -r "$TMP/skills/"* "$DEST/"
rm -rf "$TMP"

echo "Done. Skills installed:"
ls "$DEST"
echo ""
echo "Run /reload-plugins in Claude Code."
