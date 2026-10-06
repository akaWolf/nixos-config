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
      # 2.1.289), so pin the release through the package's own `manifest`
      # argument: the nixpkgs package reads version, artifact name and checksum
      # from the release's manifest.zst.json and unpacks the zstd binary, so
      # only the linux-x64 entry is needed here. versionCheckHook validates the
      # pin; drop the override once nixpkgs catches up.
      #
      # The pin tracks the "latest" channel, not "stable" (2.1.285 at the time
      # of writing): new models land there first, and a build that predates a
      # model simply refuses it as unknown -- which is how Opus 5.5 came to be
      # unavailable. Channel head and its checksum:
      #   curl -s https://downloads.claude.ai/claude-code-releases/latest
      #   curl -s https://downloads.claude.ai/claude-code-releases/<version>/manifest.zst.json
      unstableOverlay = _final: _prev: {
        claude-code = pkgs-unstable.claude-code.override {
          manifest = {
            version = "2.1.291";
            platforms.linux-x64 = {
              binary = "claude.zst";
              checksum = "659b2a4f57441eae2bad4e1ee67f93c26fe630863683463f48c7000ebeda8372";
            };
          };
        };
      };

      # qtile takes `extraPackages` as a derivation argument (it lands straight
      # in `dependencies`), so asking for qtile-extras produces a package Hydra
      # never built — it is always compiled locally, and that runs the upstream
      # test suite: ~9.5 minutes on every rebuild of the qtile environment.
      # The tests verify qtile itself, which upstream already tested on Hydra;
      # we only change its dependency list. Skip them. (They are also flaky
      # here: the REPL-server test waits a hard-coded 0.1s for a port to bind
      # and loses the race against a busy nixos-rebuild.)
      qtileSkipTestsOverlay = final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (_pyFinal: pyPrev: {
            # overrideAttrs, not overridePythonAttrs: the latter drops the
            # `override` attribute the NixOS qtile module needs for extraPackages.
            #
            # The wlroots override is a stopgap: nixos-26.05 hands qtile 0.37
            # wlroots 0.19, but its wayland backend is written against the 0.20
            # API (wlr_xcursor_image_get_buffer, the new wlr_xwayland_set_cursor)
            # and fails to compile, so the channel has no working qtile at all.
            # unstable already passes wlroots_0_20; drop it once 26.05 does.
            qtile = (pyPrev.qtile.override {
              wlroots = final.wlroots_0_20;
            }).overrideAttrs (_: { doInstallCheck = false; });
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
