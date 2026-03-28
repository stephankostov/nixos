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
    ];

  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk";
  };

  system.stateVersion = "25.11";

  security = {
    sudo.wheelNeedsPassword = false;
  };

  users = {
    mutableUsers = false; 
    users = {
      root = {
        hashedPassword = "$6$nix_user_root$Z.Bf0Ldzv01r82pXOLwCTTEcUuicabL3H0Kh0Lx/VKWzKRs2IZXBcvq/AbuIEh0hBSplAfY.RPZ5UB0ml3YFo/";
      };
      steph = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" "media" ];
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
     wireguard-tools
  ];

  nixpkgs.config.allowUnfree = true;

  networking = {
 firewall = {
  enable= true;
  logRefusedConnections = false;};
    hostName = "stephs-pi";
    networkmanager.enable = true;
    useDHCP = false;
    interfaces.end0.ipv4.addresses = [
      {
        address = "192.168.0.103";
        prefixLength = 24;
      }
    ];
    defaultGateway = {
       address = "192.168.0.1";
       interface = "end0";
    };
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

  virtualisation = {
    docker.enable = true;

    oci-containers = {
      backend = "docker";
      containers.home-assistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        autoStart = true;

        volumes = [
          "/var/lib/hass:/config"
          "/etc/localtime:/etc/localtime:ro"
          "/run/dbus:/run/dbus:ro"
        ];

        extraOptions = [
          "--privileged"
          "--network=host"
          "--device=/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_e2926cd33827ee11bee58fc1f49e3369-if00-port0:/dev/ttyUSB0"
        ];

        environment = {
          TZ = "Europe/London";
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 
    8123 # home-assistant
    62180 # wireguard
  ];

  networking.firewall.allowedUDPPorts = [
    62180  # WireGuard listenPort
  ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.nat = {
    enable = true;
    externalInterface = "end0";     # your internet uplink
    internalInterfaces = [ "wg0" ];
  };

  networking.wireguard = {
    enable = true;
    interfaces = {
      wg0 = {
        ips = [ "10.7.0.1/24" ];
        listenPort = 62180;
        privateKeyFile = "/root/wireguard/server.key";  
        mtu = 1492;
        peers = [
          {
            publicKey = "jxJfI7b1y0v5XagURfqUQAo7S1SYmJ5219ZNyNAvKno=";
            presharedKeyFile = "/root/wireguard/laptop.psk";
            allowedIPs = [ "10.7.0.2/32" ];
          }
          {
            publicKey = "3o2AmuB2gLE3LJk6yFlIFZPQ4RbdmQj0vO6OdiEJGmw=";
            presharedKeyFile = "/root/wireguard/phone.psk";
            allowedIPs = [ "10.7.0.3/32" ];
          }
        ];
      };
    };
  };

  services.plex = {
    enable = true;
    openFirewall = true;
    dataDir = "/var/lib/plex";
  };

  users.groups.media = {};
  users.users.plex.extraGroups = [ "media" ];

}

