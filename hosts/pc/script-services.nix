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
    # `systemctl start claude-server@<project>` runs an interactive claude with Remote Control
    # in ~/workspace/<project>, continuing its latest conversation. It lives in a tmux server on
    # its own socket: `claude-attach <project>` to /resume a different one locally.
    "claude-server@" = {
      description = "Claude Code with Remote Control in ~/workspace/%i";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        # tmux daemonises; when claude exits the session and server end, so systemd restarts it.
        Type = "forking";
        User = "steph";
        WorkingDirectory = "/home/steph/workspace/%i";
        Restart = "always";
        RestartSec = "10s";
        RuntimeDirectory = "claude-server/%i";
        ExecStart = "${pkgs.tmux}/bin/tmux -S /run/claude-server/%i/tmux new-session -d -s %i ${pkgs.claude-code}/bin/claude --continue --remote-control %H-%i";
        # "-": after a crash the server is already gone.
        ExecStop = "-${pkgs.tmux}/bin/tmux -S /run/claude-server/%i/tmux kill-server";
      };
      # claude's tools get the same PATH as a login shell.
      path = [ "/run/wrappers" "/etc/profiles/per-user/steph" "/run/current-system/sw" ];
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

  systemd.targets.multi-user.wants = [ "claude-server@kla-ficl.service" ];

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