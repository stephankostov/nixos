# hosts

The nixos configuration are in the `/home/steph/nixos` on all hosts.

## pi 

`ssh stephs-pi`
`cd ~/nixos`
`git pull`
`sudo nixos-rebuild switch --flake .#pi`

## pc

`ssh stephs-pc`
`cd ~/nixos`
`git pull`
`sudo nixos-rebuild switch --flake .#pc`
# docs

- `docs/claude-server.md`: the always-on Claude Code session on the pc (`claude-server@` service, `claude-attach`).
