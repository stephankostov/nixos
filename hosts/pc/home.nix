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
    };
    mlp = {
      hostname = "mlp";
      user = "s2764478";
      proxyJump = "jumphost";
    };
  };

}