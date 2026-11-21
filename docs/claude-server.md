# claude-server (pc)

A Claude Code session that runs on stephs-pc all the time, so you can use it
from the Claude app or claude.ai/code without starting it by hand.

## What runs

At boot, systemd starts `claude-server@kla-ficl.service`. It runs this inside
a tmux session, in `~/workspace/kla-ficl`:

```
claude --continue --remote-control stephs-pc-kla-ficl --permission-mode bypassPermissions
```

- `--continue` picks up the most recent conversation in that directory.
- `--remote-control` makes it show up as `stephs-pc-kla-ficl` in the Claude
  app and at claude.ai/code.
- `bypassPermissions` lets it run commands without asking. Anyone signed in to
  your Claude account can run any command on the PC through it.

claude needs a terminal, which is why it runs in tmux. That tmux uses its own
socket, `/run/claude-server/kla-ficl/tmux`, so plain `tmux ls` doesn't show it.

If claude exits or crashes, the tmux session ends, and systemd starts it again
after 10 seconds, back in the most recent conversation.

## Everyday use

```
claude-attach                                  # open the session in your terminal
                                               # Ctrl-b d to detach and leave it running
sudo systemctl restart claude-server@kla-ficl  # restart it
sudo systemctl stop claude-server@kla-ficl     # stop it until the next boot
journalctl -u claude-server@kla-ficl -f        # logs
```

### Switching to an older conversation

`/resume` only works in the terminal, not from the app. To switch:

1. `claude-attach`
2. `/resume` and pick the conversation
3. `Ctrl-b d` to detach

The app follows whichever conversation is open. It shows new messages from
then on, but not the older history of the conversation you switched to.

### Forking

At claude.ai/code (not the phone app), open the session's menu and choose
**Fork**, or fork from an earlier message. Do it while Claude is idle, since a
busy session declines the fork.

## Other projects

The service is a template: the part after `@` is a folder in `~/workspace`.

```
sudo systemctl start claude-server@<project>
claude-attach <project>
```

Only `kla-ficl` starts at boot. A project must be one you've opened `claude`
in once and accepted the trust prompt for. Claude won't start in your home
directory at all, because it never saves trust for it.

To change which project starts at boot, edit `systemd.targets.multi-user.wants`
in `hosts/pc/script-services.nix`.

## Where it's defined

- `hosts/pc/script-services.nix`: the `claude-server@` service, and starting
  `kla-ficl` at boot.
- `hosts/pc/home.nix`: the `claude-attach` command.

Apply changes with `nixos-rebuild switch` on the PC (see `CLAUDE.md`).
