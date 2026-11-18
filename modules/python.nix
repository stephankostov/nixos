{ config, lib, pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [ 
      # python versions managed per-project with uv.
      # the global python3 is only for one-off scripts and probing; don't pip install into it.
      python3
      jq
      uv
      nix-ld
    ];
    programs.nix-ld.enable = true;
  };
}