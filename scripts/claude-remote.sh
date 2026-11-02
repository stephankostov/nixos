#!/usr/bin/env bash
# Starts Claude Remote Control inside a detached tmux session, so it keeps
# running after you disconnect. Connect from claude.ai/code or the Claude app.
# Usage: claude-remote [project-dir]

SESSION="claude-remote"
DIR="${1:-$HOME}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "tmux session '$SESSION' already running. Attach with: tmux attach -t $SESSION"
  exit 0
fi

# Restart claude automatically if it ever exits.
tmux new-session -d -s "$SESSION" -c "$DIR" \
  "while true; do claude remote-control --name '${HOSTNAME}'; echo 'claude exited, restarting in 5s...'; sleep 5; done"

echo "Started in $DIR. Attach with: tmux attach -t $SESSION (detach with Ctrl-b d)"
