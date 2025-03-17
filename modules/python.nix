{ config, lib, pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [ 
      (python311.buildEnv.override {
            extraLibs = with python311Packages; [
              pip
              pytorch-bin
            ];
      })
    ];
  };
}