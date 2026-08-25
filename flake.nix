{
  description = "akaWolf NixOS — multi-host (pc-old, pc-new)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Dotfiles come straight from the public dotfiles repo; not a flake.
    dotfiles = {
      url = "github:akaWolf/dotfiles";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      # Overlay: pull selected packages from nixos-unstable while keeping the
      # rest of the system on stable. Add packages here as needed.
      # claude-code ships faster than nixpkgs picks it up (unstable is on
      # 2.1.217, master on 2.1.219), so pin the release and fetch the same
      # prebuilt binary the nixpkgs package uses. versionCheckHook validates
      # the pin; drop the override once nixpkgs catches up.
      unstableOverlay = _final: _prev: {
        claude-code = pkgs-unstable.claude-code.overrideAttrs (_: rec {
          version = "2.1.220";
          src = pkgs-unstable.fetchurl {
            url = "https://downloads.claude.ai/claude-code-releases/${version}/linux-x64/claude";
            hash = "sha256-Z09h8g/zBvMQDPkgDkw2xLcCeLW+8ohFSYGblCqJyGM=";
          };
        });
      };

      # qtile takes `extraPackages` as a derivation argument (it lands straight
      # in `dependencies`), so asking for qtile-extras produces a package Hydra
      # never built — it is always compiled locally, and that runs the upstream
      # test suite: ~9.5 minutes on every rebuild of the qtile environment.
      # The tests verify qtile itself, which upstream already tested on Hydra;
      # we only change its dependency list. Skip them. (They are also flaky
      # here: the REPL-server test waits a hard-coded 0.1s for a port to bind
      # and loses the race against a busy nixos-rebuild.)
      qtileSkipTestsOverlay = _final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (_pyFinal: pyPrev: {
            # overrideAttrs, not overridePythonAttrs: the latter drops the
            # `override` attribute the NixOS qtile module needs for extraPackages.
            qtile = pyPrev.qtile.overrideAttrs (_: { doInstallCheck = false; });
          })
        ];
      };

      # Modules shared by every host (the common base).
      commonModules = [
        { nixpkgs.overlays = [ unstableOverlay qtileSkipTestsOverlay ]; }
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
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.akawolf = import ./home/akawolf.nix;
        }
      ];

      mkHost = hostModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
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
