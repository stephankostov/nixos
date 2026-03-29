{ config, lib, pkgs, ... }:
{
  networking = {
    networkmanager.enable = true;
    hostName = "stephs-pc";
    interfaces = {
      enp4s0 = {
        ipv4.addresses = [ {
          address = "192.168.0.50";
          prefixLength = 24;
        } ];
        wakeOnLan = {
          enable = true;
        };
      };
    };
    defaultGateway = "192.168.0.1";
    nameservers = [ "1.1.1.1" "1.0.0.1" ];

  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "yes";
    };
  };
}