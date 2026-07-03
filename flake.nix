{
  description = "akaWolf NixOS — multi-host (pc-old, pc-new)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      # Modules shared by every host (the common base).
      commonModules = [
        ./modules/common.nix
        ./modules/users.nix
        ./modules/shell.nix
        ./modules/packages.nix
        ./modules/gnupg.nix
        ./modules/desktop.nix
        ./modules/smartcard.nix
        ./modules/monitoring.nix
        ./modules/scrutiny-collector.nix
        ./modules/node-exporter.nix
        ./modules/amdgpu-monitor.nix
        ./modules/amneziawg.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.akawolf = import ./home/akawolf.nix;
        }
      ];

      mkHost = hostModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = commonModules ++ [ hostModule ];
        };
    in
    {
      nixosConfigurations = {
        pc-new = mkHost ./hosts/pc-new;
        pc-old = mkHost ./hosts/pc-old;
      };
    };
}
