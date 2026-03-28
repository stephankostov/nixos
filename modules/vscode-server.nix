{ config, lib, pkgs, ... }:

let
  extensions = config.services.vscode-server-extensions;
  cfg = config.services.vscode-server;

  # VSCode Server on the remote typically lives under the user home:
  #   /home/<user>/.vscode-server/extensions
  extensionsTarget = "/home/steph/.vscode-server/extensions";

  extensionJson = pkgs.vscode-utils.toExtensionJson extensions;
  extensionJsonFile = pkgs.writeTextFile {
    name = "extensions-json";
    destination = "/share/vscode/extensions/extensions.json";
    text = extensionJson;
  };
in
{
  options.services.vscode-server-extensions = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [];
  };

  config = lib.mkIf cfg.enable {
    environment.etc."vscode-server-extensions".source = let
      subDir = "share/vscode/extensions";
      combinedExtensionsDrv = pkgs.buildEnv {
        name = "vscode-extensions";
        paths = extensions ++ lib.singleton extensionJsonFile;
      };
    in "${combinedExtensionsDrv}/${subDir}";

    # Symlink that etc entry into the user’s ~/.vscode-server/extensions
    systemd.tmpfiles.rules = [
      "L+ ${extensionsTarget} - - - - /etc/vscode-server-extensions"
    ];
  };
}