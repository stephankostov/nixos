{ config, osConfig, pkgs, ... }:

{

  home.sessionVariables = {
    HF_HOME = "/mnt/data2/hf_cache";
  };

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