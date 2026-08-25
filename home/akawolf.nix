# Home-manager user environment for akawolf. Identical on all hosts.
{ pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [
    # CLI / shell
    atool httpie git mcfly mise bat eza kitty jq most delta bc
    wget file killall nix-tree mc
    # coding
    claude-code
    clang-tools    # clang-format, clang-tidy
    # media
    mpv pulsemixer alsa-utils ffmpeg
    # system / process monitoring
    btop s-tui ttyplot lm_sensors linuxPackages.perf
    # hardware / serial / disks
    picocom android-tools usbutils hdparm gptfdisk screen beep
    smartmontools udisks btrfs-progs multipath-tools cryptsetup
    pcsc-tools
    # python with serial + requests
    (pkgs.python3.withPackages (ps: with ps; [ pyserial requests ]))
  ];

  # Dotfiles come from the dotfiles flake input (github:akaWolf/dotfiles) —
  # one copy, the laptop repo is the source of truth. Update with
  # `nix flake update dotfiles`.
  home.file.".gitconfig".source = "${inputs.dotfiles}/.gitconfig";
  home.file.".fish_aliases".source = "${inputs.dotfiles}/.fish_aliases";
  home.file.".screenrc".source = "${inputs.dotfiles}/.screenrc";
  home.file.".config/qtile".source = "${inputs.dotfiles}/.config/qtile";

  # ncurses always searches ~/.terminfo, even in processes that have no
  # TERMINFO_DIRS in their environment — a screen daemon started outside a
  # login shell could not resolve xterm-kitty, so `screen -rd` from kitty
  # died with "Cannot find terminfo entry".
  home.file.".terminfo/x/xterm-kitty".source =
    "${pkgs.kitty.terminfo}/share/terminfo/x/xterm-kitty";
  home.file."theme_ntp_background.png".source = "${inputs.dotfiles}/theme_ntp_background.png";

  # config.fish needs a NixOS-only tail: home-manager session vars via babelfish.
  home.file.".config/fish/config.fish".text =
    builtins.readFile "${inputs.dotfiles}/.config/fish/config.fish" + ''

      # load nixos home manager using babelfish
      cat /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh | babelfish | source
    '';

  # Overridable per-host (set in hosts/<host>/default.nix). Kept as the
  # earliest install baseline so it is safe on every machine.
  home.stateVersion = lib.mkDefault "24.05";
}
