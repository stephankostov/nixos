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

    services.plex = {
        enable = true;
        openFirewall = true;
        user = "plex";
        group = "media";
        dataDir = "/var/lib/plex";
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
        serverConfig = {
        LegalNotice.Accepted = true;
        Preferences = {
            General = {
            Locale = "en_GB";
            };
        };
        };
    };
}