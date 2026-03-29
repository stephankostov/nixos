{ config, lib, pkgs, ... }:
{
  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        device = "nodev";
        useOSProber = true;
      };
      efi = {
        efiSysMountPoint = "/boot"; 
      };
      timeout = 4;
    };
    supportedFilesystems = [ "ntfs" ];
  };
}