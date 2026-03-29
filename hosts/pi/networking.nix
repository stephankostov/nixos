{ config, lib, pkgs, ... }:
{
    networking = {
        hostName = "stephs-pi";
        networkmanager.enable = true;
        useDHCP = false;
        interfaces.end0.ipv4.addresses = [
        {
            address = "192.168.0.103";
            prefixLength = 24;
        }
        ];
        defaultGateway = {
        address = "192.168.0.1";
        interface = "end0";
        };
        nameservers = [ "1.1.1.1" "1.0.0.1" ];
        nat = {
            enable = true;
            externalInterface = "end0";
            internalInterfaces = [ "wg0" ];
        };
        firewall = {
            enable= true;
            logRefusedConnections = false;
            allowedTCPPorts = [ 
                8123 # home-assistant
                8384 # syncthing
             ];
            allowedUDPPorts = [ 
                62180  # WireGuard listenPort
             ];
        };
    };

    services.openssh = {
        enable = true;
        settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "yes";
        };
    };

    networking.wireguard = {
        enable = true;
        interfaces = {
            wg0 = {
                ips = [ "10.7.0.1/24" ];
                listenPort = 62180;
                privateKeyFile = config.sops.secrets.wireguard_server_private_key.path;  
                mtu = 1492;
                peers = [
                    {
                        publicKey = "jxJfI7b1y0v5XagURfqUQAo7S1SYmJ5219ZNyNAvKno=";
                        presharedKeyFile = config.sops.secrets.wireguard_client_laptop_preshared_key.path;
                        allowedIPs = [ "10.7.0.2/32" ];
                    }
                    {
                        publicKey = "3o2AmuB2gLE3LJk6yFlIFZPQ4RbdmQj0vO6OdiEJGmw=";
                        presharedKeyFile = config.sops.secrets.wireguard_client_phone_preshared_key.path;
                        allowedIPs = [ "10.7.0.3/32" ];
                    }
                ];
            };
        };
    };

    boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
    };
}