{ config, lib, pkgs, ... }:
{
    security = {
        sudo.wheelNeedsPassword = false;
    };

  users = {
    mutableUsers = false; 
    users = {
      root = {
        hashedPassword = "$6$nix_user_root$Z.Bf0Ldzv01r82pXOLwCTTEcUuicabL3H0Kh0Lx/VKWzKRs2IZXBcvq/AbuIEh0hBSplAfY.RPZ5UB0ml3YFo/";
      };
      steph = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" ];
        hashedPassword = "$6$i35KSPv2Qfy3bVcG$EOw6Ekf6wEkBw7um1SPa9xoM8OAd3Fy0de3AQHqYjhegXVCzBp4XO.juI2/5HkPL8QNhEdNLBc9mcZW0aOVM81";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOnG6J0/Ekn3UMcf2wxaN02CrT5U10FCVaZWGHTOjXMP stephank179@gmail.com"
        ];
      };
    };
  };
}