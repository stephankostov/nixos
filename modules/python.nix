{ config, lib, pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [ 
      # installing the python package wasn't working. 
      # python versions managed per-project anyway with uv. no global python installed. 
      uv
      nix-ld
    ];
    programs.nix-ld.enable = true;
  };
}