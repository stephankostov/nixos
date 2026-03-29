# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, repoRoot, ... }:

let 

in
{
  imports =
    [
      ./hardware-configuration.nix
      ./script-services.nix
      ./users.nix
      ./networking.nix
      ./boot.nix
      ./secrets.nix
    ];

  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.11"; 

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://cuda-maintainers.cachix.org" ];
      trusted-public-keys = [  "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=" ];
      trusted-users = [ "root" "steph" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than +7";
    };
  };

  environment.systemPackages = with pkgs; [
     vim
     wget
     git
     htop
     efibootmgr
     parted
     tree
     liquidctl
     lm_sensors
     tmux
     ffmpeg
     unzip 
     openrgb-with-all-plugins
     git-lfs
     fast-cli
     gcc
     sops
     age
  ];

  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g mouse on
      # other tmux settings...
    '';
  };

  systemd.tmpfiles.rules = [
  "w /sys/class/graphics/fbcon/cursor_blink - - - - 0" # disable cursor blink on default display (tty1)
  ];

}

