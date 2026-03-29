{ config, lib, pkgs, repoRoot, ... }:
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
      ssh_git_private_key = { owner = "steph"; group = "root"; mode = "0400"; };
      ssh_git_public_key = { owner = "steph"; group = "root"; mode = "0400"; };
      wireguard_server_private_key = root0400;
      wireguard_server_public_key = root0400;
      wireguard_client_laptop_preshared_key = root0400;
      wireguard_client_phone_preshared_key = root0400;
      restic_password = root0400;
      rclone_conf = root0400;
    };
  };
}