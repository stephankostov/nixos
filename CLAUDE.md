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