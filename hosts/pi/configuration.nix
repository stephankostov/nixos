# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, modulesPath, repoRoot, ... }:

let

in
{
  imports =
    [
      ./hardware-configuration.nix
      ./users.nix
      ./networking.nix
      ./services.nix
      ./secrets.nix
      ./script-services.nix
      ./backup.nix
    ];

  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  };

  system.stateVersion = "25.11";

  environment.systemPackages = with pkgs; [
     vim
     wget
     git
     htop
     unzip
     tmux
     wireguard-tools
     age
     sops
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "steph" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than +7";
    };
  };

  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g mouse on
      # other tmux settings...
    '';
  };

}

