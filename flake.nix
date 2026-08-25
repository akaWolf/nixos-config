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

      # qtile 0.36 runs its test suite in installCheckPhase and one REPL-server
      # test is timing-sensitive — it fails in the sandbox with
      # "ConnectionResetError: Connection lost" while the other 1371 pass, and
      # it already failed all four automatic reruns. nixpkgs disables a long
      # list of flaky qtile tests the same way; this adds one more.
      qtileTestOverlay = _final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (_pyFinal: pyPrev: {
            # overrideAttrs, not overridePythonAttrs: the latter drops the
            # `override` attribute that the NixOS qtile module needs to pass
            # extraPackages.
            qtile = pyPrev.qtile.overrideAttrs (old: {
              disabledTests = (old.disabledTests or [ ]) ++ [
                "test_repl_server_executes_code"
              ];
            });
          })
        ];
      };

      # Modules shared by every host (the common base).
      commonModules = [
        { nixpkgs.overlays = [ unstableOverlay qtileTestOverlay ]; }
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
