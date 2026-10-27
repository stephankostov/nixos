{ config, osConfig, pkgs, ... }:

{

  home.sessionVariables = {
    HF_HOME = "/mnt/data2/hf_cache";
  };

  # university machines. mlp is only reachable through the informatics jumphost.
  programs.ssh.matchBlocks = {
    jumphost = {
      hostname = "staff.ssh.inf.ed.ac.uk";
      user = "s2764478";
      extraOptions = {
        GSSAPIAuthentication = "yes";
        GSSAPIDelegateCredentials = "yes";
      };
    };
    mlp = {
      # full name so Kerberos can find the host's service principal.
      hostname = "mlp.inf.ed.ac.uk";
      user = "s2764478";
      proxyJump = "jumphost";
      extraOptions = {
        GSSAPIAuthentication = "yes";
        GSSAPIDelegateCredentials = "yes";
      };
    };
  };

}