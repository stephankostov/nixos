{ config, lib, pkgs, ... }:
{

  config = {

    environment.systemPackages = with pkgs; [ 
      devenv
      direnv
    ];

    programs.direnv = {
      enable = true;
      silent = true;
    }

  };
  
}