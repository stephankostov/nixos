{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    restic
    rclone
  ];

  services.restic.backups.homeserver = {
    initialize = true;
    repository = "rclone:nextcloud:restic-homeserver";
    passwordFile = config.sops.secrets.restic_password.path;
    paths = [
      "/var/lib/plex"
      "/var/lib/hass"
      "/var/lib/qbittorrent"
      "/var/lib/syncthing"
    ];

    # Nightly
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
    };

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];

    rcloneConfigFile = config.sops.secrets.rclone_conf.path;
  };
}