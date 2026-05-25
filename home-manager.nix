{
  imports = [ <home-manager/nixos> ];

  users.users.akawolf.isNormalUser = true;

  home-manager.useUserPackages = true;

  home-manager.useGlobalPkgs = true;

  home-manager.backupFileExtension = "backup";

  home-manager.users.akawolf = { pkgs, ... }: {
    home.packages = with pkgs; [
      atool
      httpie
      git
      mcfly
      pyenv
      bat
      eza
      kitty
      jq
      picocom
      android-tools
      nix-tree
      wget
      file
      killall
      usbutils
      mpv
      pulsemixer
      alsa-utils
      most
      delta
      hdparm
      gptfdisk
#      pcsc-tools
      screen
      (pkgs.python3.withPackages (ps: with ps; [
        pyserial
        requests
      ]))
    ];
    #programs.fish.enable = true;

    home.file.".gitconfig".source = ./configs/.gitconfig;
    home.file.".fish_aliases".source = ./configs/.fish_aliases;
    home.file.".config/fish/config.fish".source = ./configs/config.fish;

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "25.05";
  };
}
