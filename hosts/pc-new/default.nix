# Host: pc-new (akaWolf-PC-New) — hardware-specific config.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    ./smartd.nix
  ];

  networking.hostName = "akaWolf-PC-New";

  # First NixOS version installed on this machine. Do NOT change.
  system.stateVersion = "25.05";
  home-manager.users.akawolf.home.stateVersion = "25.05";
}
