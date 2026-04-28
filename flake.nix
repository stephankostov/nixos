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
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
      "https://cache.nixos-cuda.org"
      "https://cuda-maintainers.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "cache.nixos-cuda.org-1:dn11R2MsKRK0LMjxoJFO0h5L3fK3TnpbcFMZAGYlCGE="
    ];
  };

  outputs = { self, nixpkgs, home-manager, vscode-server, nixos-raspberrypi, sops-nix, ... }:
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

            sops-nix.nixosModules.sops

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

            sops-nix.nixosModules.sops

            vscode-server.nixosModules.default
            ./modules/vscode-server.nix
            ({ pkgs, ... }: {
              services.vscode-server.enable = true;
              services.vscode-server-extensions = with pkgs.vscode-extensions; [
                bbenoist.nix   # or nix-community.nix-ide
              ];
            })
          ];
        };
      };

    };
}
