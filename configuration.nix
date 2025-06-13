# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.efi.efiSysMountPoint = "/boot"; # Assuming /mnt/boot is mounted during installation
  boot.loader.grub.useOSProber = true;
  boot.loader.timeout = 7;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  #   useXkbConfig = true; # use xkb.options in tty.
  };

  security = {
    sudo.wheelNeedsPassword = false;
  };

   users.users.steph = {
     isNormalUser = true;
     extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
     initialPassword = "p";
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
  ];

  nixpkgs.config.allowUnfree = true;

  networking = {
    networkmanager.enable = true;
    hostName = "stephs-nixos";
    interfaces = {
      enp4s0 = {
        ipv4.addresses = [ {
          address = "192.168.0.50";
          prefixLength = 24;
        } ];
        wakeOnLan = {
          enable = true;
        };
      };
    };
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

  users.users.steph.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOnG6J0/Ekn3UMcf2wxaN02CrT5U10FCVaZWGHTOjXMP stephank179@gmail.com"
  ];

  users.users.freeloader = {
      isNormalUser = true;
      home = "/home/freeloader";
      createHome = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1SxVq0lkopOaPTeHuWUGD8xFvJVM8/9nTV9wE1djFS steph@stephs-nixos"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK8nKtigmlZv0v+pTIT+HEVih+QTds2r8NeTRHWm3q/u anton@rahmenwerk"
      ];
  };

  system.stateVersion = "24.11"; # Did you read the comment?

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://cuda-maintainers.cachix.org" ];
      trusted-public-keys = [  "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=" ];
      trusted-users = [ "root" "steph" ];
    };
    gc = {
      automatic = true;
      dates = "weekly"; # Adjust frequency as needed (e.g., weekly)
      options = "--delete-older-than +7"; # Keep the latest 10 generations
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
    liquidcfg = {
      enable = true;
      description = "AIO startup service for liquidctl";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = [
          "${pkgs.liquidctl}/bin/liquidctl initialize all"
          "${pkgs.liquidctl}/bin/liquidctl --match H1 set sync speed 20"
        ];
      };
    };
  };

}

