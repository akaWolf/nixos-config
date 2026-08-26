# Host: pc-new (akaWolf-PC-New) — hardware-specific config.
{ config, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    ./smartd.nix
    ../../modules/vpn-netns.nix
  ]
  # Optional machine-local module; imported only when present.
  ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

  networking.hostName = "akaWolf-PC-New";

  # LAN-only services. The exporters are scraped by the home server on
  # 192.168.1.100; 8000 is the kb-service API. Everything else stays closed —
  # this machine has a globally routable IPv6 address on its tunnel, so a
  # wildcard listener would otherwise answer the whole internet.
  networking.firewall.interfaces."enp5s0".allowedTCPPorts = [
    9100
    9256
    9633
    8000
  ];

  # NVIDIA RTX 2080 Ti (Turing) — proprietary driver for CUDA.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

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
  my.scrutiny-collector.devices = [
    { device = "/dev/sda";   type = "sat";  } # ata-TOSHIBA_HDWD130
    { device = "/dev/nvme0"; type = "nvme"; } # nvme-GIGABYTE_GP-ASM2NE6200TTTD
  ];

  # Podman (rootless) to cross-build the Android APK with the amd64 NDK/gradle
  # images running natively on this x86_64 host (no QEMU emulation needed).
  # docker_28 is unmaintained upstream; dockerCompat gives a `docker` CLI alias
  # and /run/docker.sock so the existing docker-based build pipeline works as-is.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # First NixOS version installed on this machine. Do NOT change.
  system.stateVersion = "25.05";
  home-manager.users.akawolf.home.stateVersion = "25.05";
}
