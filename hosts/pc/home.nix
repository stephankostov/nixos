{ config, osConfig, pkgs, ... }:

{

  home.sessionVariables = {
    HF_HOME = "/mnt/data2/hf_cache";
  };

  # `claude-server [dir] [session]`: Claude Code Remote Control server mode, in a tmux session.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "claude-server";
      runtimeInputs = [ pkgs.tmux pkgs.git ];
      text = builtins.readFile ../../scripts/claude-server.sh;
    })
  ];

  # university machines. mlp is only reachable through the informatics jumphost.
  programs.ssh.settings = {
    jumphost = {
      HostName = "staff.ssh.inf.ed.ac.uk";
      User = "s2764478";
      GSSAPIAuthentication = true;
      GSSAPIDelegateCredentials = true;
    };
    mlp = {
      # full name so Kerberos can find the host's service principal.
      HostName = "mlp.inf.ed.ac.uk";
      User = "s2764478";
      ProxyJump = "jumphost";
      GSSAPIAuthentication = true;
      GSSAPIDelegateCredentials = true;
    };
  };

}