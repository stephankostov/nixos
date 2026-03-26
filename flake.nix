{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs = { self, nixpkgs, home-manager, vscode-server, ... }:
    let
      lib = nixpkgs.lib;

      mkHost = {
        hostName,
        system,
        extraModules ? [ ],
        homeImports ? [ ./home.nix ],
      }: lib.nixosSystem {
        inherit system;
        specialArgs = {
          repoRoot = self;
        };
        modules =
          [
            ./hosts/${hostName}/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.steph = { imports = homeImports; };
            }

            vscode-server.nixosModules.default
            {
              services.vscode-server.enable = true;
            }
          ]
          ++ extraModules;
      };

      mkHome = { system }: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        modules = [ ./home.nix ];
      };

    in {
      nixosConfigurations = {
        pc = mkHost {
          hostName = "pc";
          system = "x86_64-linux";
          extraModules = [
            ./modules/nvidia.nix
            ./modules/python.nix
            ./modules/devenv.nix
          ];
        };

        pi = mkHost {
          hostName = "pi";
          system = "aarch64-linux";
          extraModules = [
          ];
        };
      };

      homeConfigurations = {
        steph-pc = mkHome { system = "x86_64-linux"; };
        steph-pi = mkHome { system = "aarch64-linux"; };
      };
    };
}
