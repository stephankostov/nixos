# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, repoRoot, ... }:

let 

in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.supportedFilesystems = [ "ntfs" ];
  boot.loader.generic-extlinux-compatible.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  #   useXkbConfig = true; # use xkb.options in tty.
  };

  system.stateVersion = "25.11";

  security = {
    sudo.wheelNeedsPassword = false;
  };

  users = {
    mutableUsers = false; # Enable this to allow changing user passwords
    users = {
      root = {
        hashedPassword = "$6$nix_user_root$Z.Bf0Ldzv01r82pXOLwCTTEcUuicabL3H0Kh0Lx/VKWzKRs2IZXBcvq/AbuIEh0hBSplAfY.RPZ5UB0ml3YFo/";
      };
      steph = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
        hashedPassword = "$6$nix_user_steph$VVxsarx0BA1RgezQ3GSeeYs.Y0UHmK6R6H8pO8TrBLIc0h97uLiOEjrCooMEN2lFYFTUgSodFZ3r6z8wgAyUD/";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIACR9JUn1C9HQdlay+PhnK0YvZq7mxQJ5a9UUtA9q6vq steph@Stephans-MacBook-Pro.local"
        ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
     vim
     wget
     git
     htop
     unzip
     tmux
  ];

  nixpkgs.config.allowUnfree = true;

  networking = {
    hostName = "stephs-pi";
    useNetworkd = true;
    useDHCP = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.0.103";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.0.1";
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "yes";
    };
  };

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

  systemd.services = {
    
  };

  systemd.timers = {
    
  };

}

