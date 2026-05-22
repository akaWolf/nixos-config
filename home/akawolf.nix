# Home-manager user environment for akawolf. Identical on all hosts.
{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # CLI / shell
    atool httpie git mcfly pyenv bat eza kitty jq most delta
    wget file killall nix-tree
    # media
    mpv pulsemixer alsa-utils
    # hardware / serial / disks
    picocom android-tools usbutils hdparm gptfdisk screen
    pcsc-tools
    # python with serial + requests
    (pkgs.python3.withPackages (ps: with ps; [ pyserial requests ]))
  ];

  # Dotfiles (sourced from repo ../configs/)
  home.file.".gitconfig".source = ../configs/.gitconfig;
  home.file.".fish_aliases".source = ../configs/.fish_aliases;
  home.file.".config/fish/config.fish".source = ../configs/config.fish;

  # Overridable per-host (set in hosts/<host>/default.nix). Kept as the
  # earliest install baseline so it is safe on every machine.
  home.stateVersion = lib.mkDefault "24.05";
}
