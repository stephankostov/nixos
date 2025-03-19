{ config, lib, pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [ 
      devenv
      direnv
      starship
    ];
  };

  programs.starship.enable = true;
}