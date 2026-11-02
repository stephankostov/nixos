#!/usr/bin/env bash
# Starts an interactive Claude Code session with Remote Control enabled, inside
# a detached tmux session so it survives disconnects. Reach it from
# claude.ai/code or the Claude app, or locally with `tmux attach`.
# Usage: claude-remote [project-dir]

SESSION="claude-remote"
DIR="${1:-$HOME}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "tmux session '$SESSION' already running. Attach with: tmux attach -t $SESSION"
  exit 0
fi

# If claude exits, drop to a shell so the tmux session stays open.
tmux new-session -d -s "$SESSION" -c "$DIR" \
  "claude --remote-control '${HOSTNAME}'; exec bash"

echo "Started in $DIR. Attach with: tmux attach -t $SESSION (detach with Ctrl-b d)"
