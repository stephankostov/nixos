#!/usr/bin/env bash
# Starts an interactive Claude Code session with Remote Control enabled, inside
# a detached tmux session so it survives disconnects. Reach it from
# claude.ai/code or the Claude app, or locally with `tmux attach`.
#
# /resume doesn't work over Remote Control, so pick the conversation here:
#   claude-remote [dir]              new conversation
#   claude-remote -c [dir]           continue the most recent conversation in dir
#   claude-remote -r <id|name> [dir] resume a specific conversation
#   claude-remote -r [dir]           open the resume picker (attaches tmux so you can choose)

SESSION="claude-remote"
RESUME_ARGS=()
ATTACH=0

case "${1:-}" in
  -c)
    RESUME_ARGS=(--continue); shift ;;
  -r)
    shift
    # Next arg is a session id/name unless it's a directory (or missing).
    if [[ -n "${1:-}" && ! -d "$1" ]]; then
      RESUME_ARGS=(--resume "$1"); shift
    else
      RESUME_ARGS=(--resume); ATTACH=1
    fi ;;
esac

DIR="${1:-$HOME}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "tmux session '$SESSION' already running. Attach with: tmux attach -t $SESSION"
  exit 0
fi

CMD=$(printf '%q ' claude "${RESUME_ARGS[@]}" --remote-control "$HOSTNAME")

# If claude exits, drop to a shell so the tmux session stays open.
tmux new-session -d -s "$SESSION" -c "$DIR" "$CMD; exec bash"

if [[ $ATTACH -eq 1 ]]; then
  echo "Pick a conversation, then detach with Ctrl-b d."
  exec tmux attach -t "$SESSION"
fi

echo "Started in $DIR. Attach with: tmux attach -t $SESSION (detach with Ctrl-b d)"
