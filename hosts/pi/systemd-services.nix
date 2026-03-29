{ config, lib, pkgs, repoRoot, ... }:
let
  ipChangeDetectScript = pkgs.writeTextFile {
    name = "ip-change-detect.py";
    executable = true;
    text = builtins.readFile (repoRoot + "/scripts/ip-change-detect.py");
  };
in
{

  systemd.services = {
    ip-change-detect = {
      description = "Send notification on public IP address change";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${ipChangeDetectScript}";
        LoadCredential = "smpt_gmail_app_password:${config.sops.secrets.smpt_gmail_app_password.path}";
      };
      path = [ pkgs.python3 ];
    };
  };

  systemd.timers = {
    ip-change-detect = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "10min";
        Unit = "ip-change-detect.service";
      };
    };
  };
}