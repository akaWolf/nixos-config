{
  description = "akaWolf NixOS — multi-host (pc-old, pc-new)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = "x86_64-linux";

      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      # Overlay: pull selected packages from nixos-unstable while keeping the
      # rest of the system on stable. Add packages here as needed.
      unstableOverlay = _final: _prev: {
        inherit (pkgs-unstable) claude-code;
      };

      # Modules shared by every host (the common base).
      commonModules = [
        { nixpkgs.overlays = [ unstableOverlay ]; }
        ./modules/common.nix
        ./modules/users.nix
        ./modules/shell.nix
        ./modules/gnupg.nix
        ./modules/desktop.nix
        ./modules/smartcard.nix
        ./modules/monitoring.nix
        ./modules/scrutiny-collector.nix
        ./modules/exporters.nix
        ./modules/process-exporter.nix
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
