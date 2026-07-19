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

  # Build initramfs on tmpfs for speed
  boot.tmp.useTmpfs = true;

  boot.kernel.sysctl = {
    "kernel.dmesg_restrict" = 0;
  };

  # Load PC speaker for beep() (motherboard buzzer)
  boot.kernelModules = [ "pcspkr" ];

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
  hardware.firmware = [ pkgs.sof-firmware ];
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
