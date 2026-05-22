# Host: pc-old (akaWolf-PC-Old) — hardware-specific config.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    ./smartd.nix
  ];

  networking.hostName = "akaWolf-PC-Old";

  # First NixOS version installed on this machine. Do NOT change.
  system.stateVersion = "24.05";
  home-manager.users.akawolf.home.stateVersion = "24.05";
}
