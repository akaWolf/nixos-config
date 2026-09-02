# Host: pc-new (akaWolf-PC-New) — hardware-specific config.
{ config, lib, pkgs, ... }:

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

  # kb-service API. Its /v1 routes do require a bearer token, but /health is
  # open and leaks the kb path and article count, it binds 0.0.0.0, and an
  # interface-scoped rule would still admit external IPv6 arriving on that
  # interface — so scope it by source like the exporters (modules/exporters.nix).
  # IPv4 only; the clients are on the LAN.
  networking.firewall.extraCommands = ''
    iptables -I nixos-fw 1 -s 192.168.1.0/24 -p tcp --dport 8000 -j nixos-fw-accept
  '';

  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -s 192.168.1.0/24 -p tcp --dport 8000 -j nixos-fw-accept 2>/dev/null || true
  '';

  # Kernel messages leave over UDP the moment they are printed, so a freeze that
  # never reaches the disk still leaves its last words on pc-old. Started as a
  # unit rather than a kernel parameter because netconsole is a module here and
  # wants the interface already up.
  #
  # The target MAC is the broadcast address on purpose: the receiver is selected
  # by IP anyway, and this keeps a hardware address out of the public repo and
  # out of the way should that NIC ever be replaced.
  systemd.services.netconsole = {
    description = "Kernel console over UDP to pc-old";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.kmod}/bin/modprobe netconsole "
        + "netconsole=6666@192.168.1.3/enp5s0,6666@192.168.1.2/ff:ff:ff:ff:ff:ff";
      ExecStop = "${pkgs.kmod}/bin/modprobe -r netconsole";
    };
  };

  # os-prober walks every partition on every disk, and on this host that means
  # touching the failing TOSHIBA. Under the rescue load its reads take seconds,
  # so on 2026-09-02 a switch sat 30 minutes inside an uninterruptible
  # `grub-probe -d /dev/sda1` before the disk answered. GRUB_OS_PROBER_SKIP_LIST
  # is no cure: 30_os-prober filters the *output* of os-prober, while the stall
  # happens inside os-prober itself, well before any filtering.
  #
  # Nothing here needs discovering anyway -- both values below were read off the
  # entry os-prober used to generate, and the ESP does not move.
  boot.loader.grub.useOSProber = false;
  boot.loader.grub.extraEntries = ''
    menuentry "Windows Boot Manager" --class windows --class os {
      insmod part_gpt
      insmod fat
      search --no-floppy --fs-uuid --set=root EC56-A21C
      chainloader /EFI/Microsoft/Boot/bootmgfw.efi
    }
  '';

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
