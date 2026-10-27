{ config, pkgs, ... }:
{
  # university VPN. the .ovpn file itself is a sops secret (uni_vpn_ovpn) so it's decrypted to /run/secrets at boot and never lands in the nix store.
  # not started automatically: `sudo systemctl start openvpn-uni` / `sudo systemctl stop openvpn-uni`, logs via `journalctl -fu openvpn-uni`.
  services.openvpn.servers.uni = {
    autoStart = false;
    config = ''
      config ${config.sops.secrets.uni_vpn_ovpn.path}

      # username on line 1, password on line 2. overrides any bare auth-user-pass in the .ovpn so it doesn't prompt.
      auth-user-pass ${config.sops.secrets.uni_vpn_auth.path}

      # push the VPN's DNS servers into systemd-resolved (networking.nix uses resolved, so the default resolvconf script won't work).
      script-security 2
      up ${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved
      down ${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved
      down-pre
    '';
  };
}
