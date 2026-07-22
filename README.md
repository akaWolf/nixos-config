# nixos-config

NixOS flake for two desktops: `pc-old` (akaWolf-PC-Old) and `pc-new`
(akaWolf-PC-New). One shared base, thin per-host layers.

## Layout

    flake.nix            inputs (nixos-26.05, home-manager, unstable overlay)
                         and host wiring; custom options live under `my.*`
    modules/             shared system modules, one concern per file
    hosts/<host>/        hardware-configuration, disks, smartd device list,
                         host-specific quirks (GPU driver, sensors, VMs)
    home/akawolf.nix     home-manager user environment
    configs/             dotfiles deployed via home-manager

## Machine-local modules

`hosts/pc-new/default.nix` imports `./private.nix` when the file exists:

    ] ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

The file (and the modules it imports) lives on a machine-local branch and
never appears in this repository. Both branches keep every shared file
byte-identical, so merges never conflict. Note the flake only sees
git-tracked files: an uncommitted private.nix silently drops out of the
build instead of failing it.

## Deploy

On the machine, after pulling the branch:

    sudo nixos-rebuild switch --flake /etc/nixos#pc-old   # or #pc-new

Run `nixos-rebuild build` first when the change is risky; `switch` does not
reboot, new kernels take effect on the next boot.
