# Host: pc-old (akaWolf-PC-Old) — hardware-specific config.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    ./smartd.nix
  ];

  networking.hostName = "akaWolf-PC-Old";

  # Motherboard SuperIO sensors (ITE IT8728F) — driver isn't auto-loaded,
  # and ACPI claims the chip's I/O ports unless told to back off.
  boot.kernelModules = [ "it87" ];
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];

  # Collector strips "/dev/" prefix internally — by-id paths break (see
  # smart_support:false in early debug). The disk SN is the real identity
  # in scrutiny; sd[a-d] enumeration just needs to be stable per boot.
  services.scrutiny-collector.devices = [
    { device = "/dev/sda"; type = "sat"; } # ata-WDC_WD60EFPX-68C5ZN0
    { device = "/dev/sdb"; type = "sat"; } # ata-ST2000NM0033-9ZM175
    { device = "/dev/sdc"; type = "sat"; } # ata-OCZ-VERTEX3
    { device = "/dev/sdd"; type = "sat"; } # ata-PLEXTOR_PX-128M5Pro
  ];

  # First NixOS version installed on this machine. Do NOT change.
  system.stateVersion = "24.05";
  home-manager.users.akawolf.home.stateVersion = "24.05";
}
