# Host: pc-new (akaWolf-PC-New) — hardware-specific config.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    ./smartd.nix
  ];

  networking.hostName = "akaWolf-PC-New";

  # Motherboard SuperIO sensors (ITE IT8792E). The driver isn't auto-loaded
  # and ACPI claims the I/O ports unless told otherwise. IT8792E isn't in
  # mainline it87's supported chip list; map it to the closest sibling
  # (IT8628E) so probe succeeds.
  boot.kernelModules = [ "it87" ];
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  boot.extraModprobeConfig = ''
    options it87 force_id=0x8628 ignore_resource_conflict=1
  '';

  # See pc-old/default.nix for why by-id is not used.
  services.scrutiny-collector.devices = [
    { device = "/dev/sda";   type = "sat";  } # ata-TOSHIBA_HDWD130
    { device = "/dev/nvme0"; type = "nvme"; } # nvme-GIGABYTE_GP-ASM2NE6200TTTD
  ];

  # First NixOS version installed on this machine. Do NOT change.
  system.stateVersion = "25.05";
  home-manager.users.akawolf.home.stateVersion = "25.05";
}
