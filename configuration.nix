# /etc/nixos/configuration.nix
{ config, lib, pkgs, ... }:

{
  ##########################################################################
  # Imports
  ##########################################################################
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # Home Manager configuration
      ./home-manager.nix
    ];

  ##########################################################################
  # System state
  ##########################################################################
  # This option defines the first version of NixOS you have installed
  # on this machine. Do NOT change after installation.
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "25.05";

  # Copy the configuration.nix to /run/current-system/configuration.nix
  system.copySystemConfiguration = true;

  ##########################################################################
  # User & shell
  ##########################################################################
  users.defaultUserShell = pkgs.fish;

  programs.fish.enable = true;
  # programs.fish.useBabelfish = true; # optional

  # Disable root account
  # Disabled, since doesn't work w/o users.mutableUsers = false which in turn needs to hardcode passwords here in config
  # users.users.root.hashedPassword = "!";

  users.users.akawolf = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" "reader" "dialout" "input" ]; # Enable sudo and audio access
    packages = with pkgs; [
      # firefox
      # tree
    ];

    # SSH keys for login
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC1UZUcjfpcxoG89bVvCM5XxDdgnd5bkkM8MaijEI9oT akawolf0@gmail.com"
    ];
  };

  # GnuPG agent configuration
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-qt;
  };

  ##########################################################################
  # Packages
  ##########################################################################
  environment.systemPackages = with pkgs; [
    babelfish
    fishPlugins.pure
    ntfs3g
 #   pcsc-tools
 #   ccid
  ];

  ##########################################################################
  # Bootloader
  ##########################################################################
  # Use systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Build initramfs on tmpfs for speed
  boot.tmp.useTmpfs = true;

  ##########################################################################
  # Networking
  ##########################################################################
  networking.hostName = "akaWolf-nixos"; # Set hostname
  services.openssh.enable = true; # Enable ssh

  # Firewall
  networking.firewall.enable = false;
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # Choose only one networking option:
  # networking.wireless.enable = true;  # via wpa_supplicant
  # networking.networkmanager.enable = true; # recommended for desktops

  # Proxy settings example
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  ##########################################################################
  # Time & locale
  ##########################################################################
  time.timeZone = "Europe/Moscow";

  # Default system locale
  i18n.defaultLocale = "en_US.UTF-8";

  ##########################################################################
  # Console
  ##########################################################################
  console = {
    font = "UniCyrExt_8x16";
    #keyMap = "us"; # optional
    useXkbConfig = true; # use xkb.options in tty
  };

  ##########################################################################
  # X11 / Desktop
  ##########################################################################
  services.xserver.enable = true;

  # Enable Qtile window manager
  services.xserver.windowManager.qtile = {
    enable = true;
    extraPackages = python3Packages: with python3Packages; [
      qtile-extras
    ];
  };

  # X11 keyboard configuration
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "intl-unicode,";
  services.xserver.xkb.options = "grp:caps_toggle,terminate:ctrl_alt_bksp,compose:rctrl";

  ##########################################################################
  # Printing
  ##########################################################################
  # services.printing.enable = true; # Enable CUPS

  ##########################################################################
  # Sound
  ##########################################################################
  services.pipewire = {
    enable = true;

    # ALSA support
    alsa.enable = true;
    alsa.support32Bit = true;

    # PulseAudio & JACK bridges
    pulse.enable = true;
    jack.enable = true;
  };

  # Touchpad support
  services.libinput.enable = true;

  ##########################################################################
  # Firmware & microcode
  ##########################################################################
  hardware.firmware = [
    pkgs.sof-firmware
  ];

  # Automatically enable all firmware packages
  hardware.enableAllFirmware = true;

  # Allow non-free packages
  nixpkgs.config.allowUnfree = true;

  ##########################################################################
  # Nix settings & garbage collection
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
  # Udev
  ##########################################################################
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666"
    ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="pcspkr", MODE="0660", GROUP="input"
  '';

  ##########################################################################
  # Locate service
  ##########################################################################
  services.locate = {
    enable = true;
    package = pkgs.plocate;
  };

  ##########################################################################
  # Kernel
  ##########################################################################
  boot.kernel.sysctl = {
    "kernel.dmesg_restrict" = 0;
  };

  # PCSC-Lite daemon for smart cards
#services.pcscd = {
#  enable = true;
#  # Add the ccid package to the search path for drivers
#  plugins = [ pkgs.ccid ];
#  
#  # Use the correct LIBPATH we found earlier
#  readerConfigs = [
#    ''
#      FRIENDLYNAME      "PL2303 Serial Reader"
#      DEVICENAME        /dev/ttyUSB0
#      LIBPATH           ${pkgs.ccid}/pcsc/drivers/serial/libccidtwin.so
#      CHANNELID         1
#    ''
#  ];
#};


}
