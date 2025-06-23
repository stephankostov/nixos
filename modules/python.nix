{ config, lib, pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [ 
      (python311.withPackages (ps: with ps; [
        pip
        pytorch-bin
        huggingface-hub
      ]))
      uv
      nix-ld # for dynamic dependancy linking
    ];
    programs.nix-ld.enable = true;
  };
  
}