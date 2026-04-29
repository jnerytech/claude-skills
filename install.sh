#!/usr/bin/env bash
# Install claude-skills skills.
#
# Global (~/.claude/skills):
#   curl -fsSL https://raw.githubusercontent.com/jnerytech/claude-skills/master/install.sh | bash
#
# Project-local (run from project root):
#   curl -fsSL https://raw.githubusercontent.com/jnerytech/claude-skills/master/install.sh | bash -s .

set -e

# Resolve arg to absolute path, default to ~/.claude/skills
if [ -n "$1" ]; then
  DEST="$(cd "$1" && pwd)/.claude/skills"
else
  DEST="$HOME/.claude/skills"
fi

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
