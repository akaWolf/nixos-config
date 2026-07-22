# Common system base — shared by all hosts.
{ pkgs, ... }:

{
  ##########################################################################
  # Bootloader
  ##########################################################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Small ESP (~100M) — keep only the last N generations in /boot.
  boot.loader.systemd-boot.configurationLimit = 2;

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
  networking.firewall.enable = false;

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
}
