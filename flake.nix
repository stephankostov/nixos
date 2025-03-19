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

  outputs = { self, nixpkgs, home-manager, vscode-server }:
    let 
      system = "x86_64-linux";
      pkgs = import nixpkgs {
	inherit system;
	config.allowUnfree = true;
      };
      lib = nixpkgs.lib;
    in {
      nixosConfigurations = {
	nixos = lib.nixosSystem {
	  inherit system;
	  modules = [ 
      ./configuration.nix 
      ./modules/nvidia.nix
      ./modules/python.nix
      home-manager.nixosModules.home-manager {
	      home-manager.useGlobalPkgs = true;
	      home-manager.useUserPackages = true;
        home-manager.users.steph = { imports = [ ./home.nix ]; }; 
      }
      vscode-server.nixosModules.default {
          services.vscode-server.enable = true;
          services.vscode-server.enableFHS = true;
      }
	  ];
	};
      };
      homeConfigurations = {
	nixos = home-manager.lib.homeManagerConfiguration {
	  inherit system pkgs;
	  username = "steph";
	  homeDirectory = "/home/steph";
	  configuration = {
	    imports = [
	     ./home.nix
	    ];
	  };
	};
      };
    };
}
