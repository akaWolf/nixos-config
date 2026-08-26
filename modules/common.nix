# Common system base — shared by all hosts.
{ pkgs, ... }:

{
  ##########################################################################
  # Bootloader
  ##########################################################################
  # GRUB, not systemd-boot. systemd-boot can only read FAT, so every retained
  # generation had to live in the 100M ESP — ~54M per generation next to 26M of
  # Windows bootloader, so exactly one fit and there was no rollback entry in
  # the boot menu. Neither machine can grow its ESP without relocating a
  # neighbouring partition (root on pc-old, 1.7T of NTFS on pc-new). GRUB reads
  # ext4, so kernels stay in the nix store on the root filesystem and the ESP
  # only carries grubx64.efi (~140K). The ESP mounts at /boot/efi; /boot itself
  # is a plain directory on root.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;   # both machines dual-boot Windows
    configurationLimit = 20;
  };

  # Shorter boot-menu auto-select (default is 5s).
  boot.loader.timeout = 3;

  # /tmp on tmpfs
  boot.tmp.useTmpfs = true;

  boot.kernel.sysctl = {
    "kernel.dmesg_restrict" = 0;
  };

  # PC speaker for beep(1). boot.kernelModules is deliberately not used:
  # it goes through systemd-modules-load, which honours the blacklist that
  # kmod's ubuntu.conf sets for pcspkr ("ugly and loud noise", Ubuntu #77010).
  # An explicit modprobe by name is not affected by that blacklist.
  systemd.services.load-pcspkr = {
    description = "Load pcspkr, blacklisted by kmod's default config";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = "${pkgs.kmod}/bin/modprobe pcspkr";
  };

  # Let group "input" access /dev/input/pcspkr
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="pcspkr", MODE="0660", GROUP="input"
  '';

  ##########################################################################
  # Networking (hostName is per-host)
  ##########################################################################
  services.openssh.enable = true;
  # The openssh module opens its port in the firewall by default; we scope SSH
  # ourselves below, by source subnet and IPv4 only.
  services.openssh.openFirewall = false;

  # Firewall on. Services here bind wildcard addresses, and both machines hold a
  # globally routable IPv6 address on their LAN interface — without this they
  # answer the internet, not just the LAN.
  #
  # Nothing is opened globally, not even SSH: the router forwards no port to
  # these hosts, so every legitimate client is already on the LAN. SSH is
  # therefore scoped by source subnet and to IPv4 only, like the exporters.
  # Consequence worth knowing: the machines can no longer reach each other over
  # their global IPv6 addresses, only over 192.168.1.x.
  networking.firewall.enable = true;

  networking.firewall.extraCommands = ''
    iptables -I nixos-fw 1 -s 192.168.1.0/24 -p tcp --dport 22 -j nixos-fw-accept
  '';

  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -s 192.168.1.0/24 -p tcp --dport 22 -j nixos-fw-accept 2>/dev/null || true
  '';

  # AmneziaWG on every host: the unit is gated by ConditionPathExists on
  # /etc/amnezia/amneziawg/<iface>.conf, hosts without the config skip it.
  my.amneziawg = {
    enable = true;
    interfaces = [ "wg0" ];
  };

  ##########################################################################
  # Time & locale
  ##########################################################################
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    font = "UniCyrExt_8x16";
    useXkbConfig = true;
  };

  ##########################################################################
  # Firmware & nixpkgs
  ##########################################################################
  # enableAllFirmware already includes sof-firmware and friends.
  hardware.enableAllFirmware = true;
  nixpkgs.config.allowUnfree = true;

  ##########################################################################
  # Nix settings & GC
  ##########################################################################
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    use-xdg-base-directories = true;
    sandbox = true;
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  ##########################################################################
  # Locate
  ##########################################################################
  services.locate = {
    enable = true;
    package = pkgs.plocate;
  };

  ##########################################################################
  # Misc system tools
  ##########################################################################
  # Userland NTFS tools (mkntfs, ntfsfix); mounts use the kernel ntfs3 driver.
  environment.systemPackages = [ pkgs.ntfs3g ];
}
