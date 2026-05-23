# Host: pc-new (akaWolf-PC-New) — hardware-specific config.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    ./smartd.nix
  ];

  networking.hostName = "akaWolf-PC-New";

  # See pc-old/default.nix for why by-id is not used.
  services.scrutiny-collector.devices = [
    { device = "/dev/sda";   type = "sat";  } # ata-TOSHIBA_HDWD130
    { device = "/dev/nvme0"; type = "nvme"; } # nvme-GIGABYTE_GP-ASM2NE6200TTTD
  ];

  # First NixOS version installed on this machine. Do NOT change.
  system.stateVersion = "25.05";
  home-manager.users.akawolf.home.stateVersion = "25.05";
}
