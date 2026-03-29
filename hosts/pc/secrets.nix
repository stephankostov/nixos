{ config, pkgs, ... }:
{
    sops = {
        defaultSopsFile = repoRoot + "/secrets/secrets.json";
        defaultSopsFormat = "json";
        age.keyFile = "/root/.config/age/sops-nix-keys.txt";
        secrets = {
            smpt_gmail_app_password = root0400;
            ssh_git_private_key = { owner = "steph"; group = "root"; mode = "0400"; };
            ssh_git_public_key = { owner = "steph"; group = "root"; mode = "0400"; };
        };
    };
}