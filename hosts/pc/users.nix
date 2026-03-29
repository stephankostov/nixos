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
        hashedPassword = "$6$nix_user_steph$VVxsarx0BA1RgezQ3GSeeYs.Y0UHmK6R6H8pO8TrBLIc0h97uLiOEjrCooMEN2lFYFTUgSodFZ3r6z8wgAyUD/";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOnG6J0/Ekn3UMcf2wxaN02CrT5U10FCVaZWGHTOjXMP stephank179@gmail.com"
        ];
      };
    };
  };
}