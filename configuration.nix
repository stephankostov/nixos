# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let 
  thermalShutdownScript = pkgs.writeTextFile {
    name = "thermal-shutdown.py";
    executable = true;
    destination = "/bin/thermal-shutdown.py";
    text = builtins.readFile ./scripts/thermal-shutdown.py;
  };
  fanControlScript = pkgs.writeTextFile {
    name = "fan-control.py";
    executable = true;
    destination = "/bin/fan-control.py";
    text = builtins.readFile ./scripts/fan-control.py;
  };
  idleShutdownScript = pkgs.writeTextFile {
    name = "idle-shutdown.py";
    executable = true;
    destination = "/bin/idle-shutdown.py";
    text = builtins.readFile ./scripts/idle-shutdown.py;
  };
in
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
  boot.loader.timeout = 4;
  boot.supportedFilesystems = [ "ntfs" ];

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  #   useXkbConfig = true; # use xkb.options in tty.
  };

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/C4AAD0FFAAD0EF44";
    fsType = "ntfs-3g";
    options = [ 
      "rw"         
      "uid=1000"
      "gid=100"
    ];
  };

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
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOnG6J0/Ekn3UMcf2wxaN02CrT5U10FCVaZWGHTOjXMP stephank179@gmail.com"
        ];
      };
      freeloader = {
        isNormalUser = true;
        createHome = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1SxVq0lkopOaPTeHuWUGD8xFvJVM8/9nTV9wE1djFS steph@stephs-nixos"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK8nKtigmlZv0v+pTIT+HEVih+QTds2r8NeTRHWm3q/u anton@rahmenwerk"
        ];
      };
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

    # wireless = {
    #   enable = true;
    #   networks = {
    #     "Warrender Toad" = {
    #       pskRaw = "b3ecb89a420a35f85540fbbccf5ff36f2b8d361481036e7babd42c5eaf5737c8";
    #     };
    #   };
    # };

  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "yes";
    };
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
    fan-control = {
      description = "Software fan curve via sensors + liquidctl";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "root";
        Restart = "always";
        RestartSec = "5s";
        ExecStart = "${fanControlScript}/bin/fan-control.py --interval 30 --curve 30:30 50:60 80:100";
      };
      path = [ pkgs.lm_sensors pkgs.liquidctl pkgs.python3 pkgs.coreutils ];
    };
    thermal-shutdown = {
      description = "Shutdown if temperatures stay too high";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${thermalShutdownScript}/bin/thermal-shutdown.py --max-c 99 --persist-sec 600";
        LoadCredential = "smpt_gmail_app_password:/etc/credstore/smpt_gmail_app_password";
      };
      path = [ pkgs.lm_sensors pkgs.python3 pkgs.util-linux pkgs.coreutils ];
    };
    idle-shutdown = {
      description = "Shutdown system if idle";
      serviceConfig = {
        Type = "simple";
        User = "root";
        ExecStart = "${idleShutdownScript}/bin/idle-shutdown.py --threshold 10 --checks 6 --between-sec 60";
      };
      path = [ pkgs.systemd pkgs.python3 ];
    };
  };

  systemd.timers = {
    thermal-shutdown = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "60s";
        Unit = "thermal-shutdown.service";
      };
    };
    nightly-shutdown = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = [
          "*-*-* 23:00:00"
          "*-*-* 00:00:00"
          "*-*-* 01:00:00"
          "*-*-* 03:00:00"
          "*-*-* 05:00:00"
        ];
        Persistent = false;
        Unit = "idle-shutdown.service";
      };
    };
  };

  systemd.tmpfiles.rules = [
  "w /sys/class/graphics/fbcon/cursor_blink - - - - 0" # disable cursor blink on default display (tty1)
  ];

}

