# Home-manager user environment for akawolf. Identical on all hosts.
{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # CLI / shell
    atool httpie git mcfly mise bat eza kitty jq most delta
    wget file killall nix-tree mc
    # coding
    claude-code
    clang-tools    # clang-format, clang-tidy
    # media
    mpv pulsemixer alsa-utils
    # system / process monitoring
    btop s-tui ttyplot lm_sensors linuxPackages.perf
    # hardware / serial / disks
    picocom android-tools usbutils hdparm gptfdisk screen beep
    smartmontools udisks btrfs-progs multipath-tools cryptsetup
    pcsc-tools
    # python with serial + requests
    (pkgs.python3.withPackages (ps: with ps; [ pyserial requests ]))
  ];

  # Dotfiles (sourced from repo ../configs/)
  home.file.".gitconfig".source = ../configs/.gitconfig;
  home.file.".fish_aliases".source = ../configs/.fish_aliases;
  home.file.".config/fish/config.fish".source = ../configs/config.fish;
  home.file.".screenrc".source = ../configs/.screenrc;

  # Overridable per-host (set in hosts/<host>/default.nix). Kept as the
  # earliest install baseline so it is safe on every machine.
  home.stateVersion = lib.mkDefault "24.05";
}
