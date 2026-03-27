{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
  };

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  outputs = { self, nixpkgs, home-manager, vscode-server, nixos-raspberrypi, ... }:
    let
      lib = nixpkgs.lib;
    in {
      nixosConfigurations = {
        pc = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            repoRoot = self;
          };
          modules = [
            ./hosts/pc/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.steph = { imports = [ ./home.nix ]; };
            }

            vscode-server.nixosModules.default
            {
              services.vscode-server.enable = true;
            }

            ./modules/nvidia.nix
            ./modules/python.nix
            ./modules/devenv.nix
          ];
        };

        pi = nixos-raspberrypi.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            repoRoot = self;
            inherit nixos-raspberrypi;
          };
          modules = [
            ({ ... }: {
              imports = with nixos-raspberrypi.nixosModules; [
                raspberry-pi-5.base
                raspberry-pi-5.bluetooth
              ];
            })

            ./hosts/pi/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.steph = { imports = [ ./home.nix ]; };
            }
            vscode-server.nixosModules.default
            {
              services.vscode-server.enable = true;
            }
          ];
        };
      };

    };
}
