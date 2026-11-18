#!/usr/bin/env bash
# Start (or attach to) a tmux session running Claude Code in Remote Control server mode.
# Each conversation started from claude.ai/code or the Claude app spawns its own session.
# Usage: claude-server [project-dir] [session-name]
set -euo pipefail

PROJECT_DIR="${1:-$PWD}"
SESSION="${2:-claude-server}"
NAME="${CLAUDE_RC_NAME:-$HOSTNAME}"

# Use worktree mode in git repos, otherwise share the directory
if git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  SPAWN=worktree
else
  SPAWN=same-dir
fi

CMD=$(printf '%q ' claude remote-control --name "$NAME" --spawn "$SPAWN" --permission-mode bypassPermissions)

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "tmux session '$SESSION' already running."
else
  # Keep the window open if claude exits, so errors stay visible
  tmux new-session -d -s "$SESSION" -c "$PROJECT_DIR" "$CMD; echo; echo \"claude exited (\$?). Press enter to close.\"; read"
  echo "Started '$SESSION' in $PROJECT_DIR (spawn: $SPAWN)."
fi

# Attach if run from an interactive terminal outside tmux
if [[ -t 1 && -z "${TMUX:-}" ]]; then
  exec tmux attach -t "$SESSION"
fi
