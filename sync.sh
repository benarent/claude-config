#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

usage() {
  echo "Usage: $(basename "$0") <push|pull>"
  echo "  push  - Copy local ~/.claude config into this repo"
  echo "  pull  - Install repo config into ~/.claude"
  exit 1
}

[[ $# -eq 1 ]] || usage

case "$1" in
  push)
    echo "Pushing ~/.claude config to repo..."
    cp "$CLAUDE_DIR/CLAUDE.md" "$REPO_DIR/"
    cp "$CLAUDE_DIR/settings.json" "$REPO_DIR/"
    cp "$CLAUDE_DIR/statusline-command.sh" "$REPO_DIR/"
    rsync -av --delete --exclude='.DS_Store' "$CLAUDE_DIR/skills/" "$REPO_DIR/skills/"
    echo "Done. Review changes with: cd $REPO_DIR && git diff"
    ;;
  pull)
    echo "Installing repo config to ~/.claude..."
    mkdir -p "$CLAUDE_DIR/skills"
    cp "$REPO_DIR/CLAUDE.md" "$CLAUDE_DIR/"
    cp "$REPO_DIR/settings.json" "$CLAUDE_DIR/"
    cp "$REPO_DIR/statusline-command.sh" "$CLAUDE_DIR/"
    rsync -av --delete --exclude='.DS_Store' "$REPO_DIR/skills/" "$CLAUDE_DIR/skills/"
    echo "Done. Config installed to $CLAUDE_DIR"
    ;;
  *)
    usage
    ;;
esac
