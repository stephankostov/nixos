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
    mlp1 = {
      # full name so Kerberos can find the host's service principal.
      HostName = "mlp1.inf.ed.ac.uk";
      User = "s2764478";
      ProxyJump = "jumphost";
      GSSAPIAuthentication = true;
      GSSAPIDelegateCredentials = true;
    };
    # EIDF GPU service. the k8s login node is only reachable through the EIDF gateway.
    eidf-gateway = {
      HostName = "eidf-gateway.epcc.ed.ac.uk";
      User = "s2764478-infk8s";
      IdentityFile = osConfig.sops.secrets.ssh_eidf.path;
      IdentitiesOnly = true;
    };
    eidf-infk8s = {
      HostName = "10.24.7.178";
      User = "s2764478-infk8s";
      ProxyJump = "eidf-gateway";
      IdentityFile = osConfig.sops.secrets.ssh_eidf.path;
      IdentitiesOnly = true;
    };
  };

}