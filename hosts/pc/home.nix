{ config, osConfig, pkgs, ... }:

{

  home.sessionVariables = {
    HF_HOME = "/mnt/data2/hf_cache";
  };

  home.packages = [
    # `claude-attach [project]`: attach to the claude-server@<project> service's tmux session.
    # See docs/claude-server.md.
    (pkgs.writeShellApplication {
      name = "claude-attach";
      runtimeInputs = [ pkgs.tmux ];
      text = ''exec tmux -S "/run/claude-server/''${1:-kla-ficl}/tmux" attach'';
    })
    # for one-off scripts and probing; projects use uv-managed pythons.
    pkgs.python3
    pkgs.jq
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