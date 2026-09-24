{ config, lib, pkgs, ... }:
{
  networking = {
    hostName = "stephs-pc";
    # interfaces = {
    #   enp4s0 = {
    #     ipv4.addresses = [ {
    #       address = "192.168.0.50";
    #       prefixLength = 24;
    #     } ];
    #     wakeOnLan = {
    #       enable = true;
    #     };
    #   };
    # };
    # defaultGateway = "192.168.0.1";
    # nameservers = [ "1.1.1.1" "1.0.0.1" ];
    networkmanager = {
       enable = true;
       # hand DNS to systemd-resolved rather than writing resolv.conf directly. without it, tailscale's MagicDNS owns resolv.conf and forwards to whatever upstreams NM last gave it; an eduroam reconnect can leave that list empty ("no upstream resolvers set, returning SERVFAIL") until NM is restarted. with resolved, tailscale only configures the tailscale0 link and wlo1 keeps its own servers.
       dns = "systemd-resolved";
       ensureProfiles = {
          environmentFiles = [
            config.sops.secrets.eduroam_env.path # this is a bit of hack. use sops-nix to decrypt the password and put it in an env file, then read that env file to make the environment config in the networkmanager profile. this is because networkmanager doesn't support sops directly.
          ];
          profiles.eduroam = {
            connection = {
              id = "eduroam";
              type = "wifi";
            };
            wifi = {
              mode = "infrastructure";
              ssid = "eduroam";
            };
            wifi-security = {
              key-mgmt = "wpa-eap";
            };
            "802-1x" = {
              eap = "peap";
              identity = "$EDUROAM_USERNAME";
              password = "$EDUROAM_PASSWORD";
              phase2-auth = "mschapv2";
              ca-cert = "/etc/ssl/certs/ca-certificates.crt";
              domain-suffix-match = "ed.ac.uk";
            };
            ipv4.method = "auto";
            ipv6 = {
              method = "auto";
              addr-gen-mode = "default";
            };
          };
       };
    };

  };

  services.resolved = {
    enable = true;
    # only consulted when no link has a working DNS server, so campus-internal names still resolve via eduroam's servers.
    settings.Resolve.FallbackDNS = [ "1.1.1.1" "1.0.0.1" ];
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
