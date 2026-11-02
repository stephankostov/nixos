{ config, lib, pkgs, ... }:
{

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

    # Home Assistant runs as root in Docker, so its files are root-owned.
    # Give the hass group read/write on existing files, and a default ACL so
    # files HA creates later are group-writable too.
    systemd.tmpfiles.rules = [
        "A+ /var/lib/hass - - - - group:hass:rwX,default:group:hass:rwX"
    ];

    # /var/lib/hass is a git repo owned by root; let steph use git in it.
    programs.git = {
        enable = true;
        config.safe.directory = "/var/lib/hass";
    };

    services.plex = {
        enable = false;
        openFirewall = true;
        user = "plex";
        group = "media";
        dataDir = "/var/lib/plex";
    };

    services.jellyfin = {
        enable = true;
        openFirewall = true;   # opens TCP 8096/8920 and UDP 1900/7359
        group = "media";       # same group as Plex, so it can read your library
        dataDir = "/var/lib/jellyfin";  # where to store metadata and config
    };

    services.audiobookshelf = {
        enable = true;
        openFirewall = true;
        host = "0.0.0.0";      # bind all interfaces; default 127.0.0.1 is Pi-local only
        port = 8041;           # 8040 is qBittorrent's web UI
        group = "media";       # read access to /mnt/storage/media/books
    };

    services.syncthing = {
        enable = true;
        user = "syncthing";
        group = "syncthing";
        dataDir = "/var/lib/syncthing";
        configDir = "/var/lib/syncthing/.config/syncthing";
        openDefaultPorts = true;
        guiAddress = "0.0.0.0:8384";
    };

    services.qbittorrent = {
        enable = true;
        openFirewall = true;
        torrentingPort = 64701;
        webuiPort = 8040;
        user = "qbittorrent"; 
        group = "media";
        profileDir = "/var/lib/qbittorrent";  
    };
}