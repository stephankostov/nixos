{ config, lib, pkgs, ... }:
{
  environment.sessionVariables = {
    HF_HOME = "/mnt/data2/hf_cache";
  };
}