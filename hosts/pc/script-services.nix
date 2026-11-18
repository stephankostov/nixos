{ config, lib, pkgs, repoRoot, ... }:
let
  thermalShutdownScript = pkgs.writeTextFile {
    name = "thermal-shutdown.py";
    executable = true;
    destination = "/bin/thermal-shutdown.py";
    text = builtins.readFile (repoRoot + "/scripts/thermal-shutdown.py");
  };
  fanControlScript = pkgs.writeTextFile {
    name = "fan-control.py";
    executable = true;
    destination = "/bin/fan-control.py";
    text = builtins.readFile (repoRoot + "/scripts/fan-control.py");
  };
  idleShutdownScript = pkgs.writeTextFile {
    name = "idle-shutdown.py";
    executable = true;
    destination = "/bin/idle-shutdown.py";
    text = builtins.readFile (repoRoot + "/scripts/idle-shutdown.py");
  };
in
{

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
        LoadCredential = "smpt_gmail_app_password:${config.sops.secrets.smpt_gmail_app_password.path}";
      };
      path = [ pkgs.lm_sensors pkgs.python3 pkgs.util-linux pkgs.coreutils ];
    };
    idle-shutdown = {
      description = "Shutdown system if idle";
      serviceConfig = {
        Type = "simple";
        User = "root";
        ExecStart = "${idleShutdownScript}/bin/idle-shutdown.py --checks 15 --between-sec 120";
      };
      path = [
        pkgs.systemd
        pkgs.python3
        pkgs.procps
        pkgs.coreutils
      ];
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

}