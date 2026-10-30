{ config, pkgs, repoRoot, ... }:
let 
  root0400 = { owner = "root"; group = "root"; mode = "0400"; };
in
{
    sops = {
        defaultSopsFile = repoRoot + "/secrets/secrets.json";
        defaultSopsFormat = "json";
        age.keyFile = "/root/.config/age/sops-nix-keys.txt";
        secrets = {
            smpt_gmail_app_password = root0400;
            ssh_git = { owner = "steph"; group = "root"; mode = "0400"; };
            eduroam_env = root0400;
            uni_vpn_ovpn = root0400;
            uni_vpn_auth = root0400;
            # binary keytab, its own sops file: see kerberos.nix.
            krb5_keytab = { owner = "steph"; group = "root"; mode = "0400"; format = "binary"; sopsFile = repoRoot + "/secrets/krb5.keytab"; };
        };
    };
}