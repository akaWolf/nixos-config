{
  imports = [ <home-manager/nixos> ];

  users.users.akawolf.isNormalUser = true;

  home-manager.useUserPackages = true;

  home-manager.useGlobalPkgs = true;

  home-manager.users.akawolf = { pkgs, ... }: {
    home.packages = with pkgs; [ atool httpie git mcfly pyenv bat eza ];
    #programs.fish.enable = true;

    home.file.".gitconfig".source = ./configs/.gitconfig;
    home.file.".fish_aliases".source = ./configs/.fish_aliases;
    home.file.".config/fish/config.fish".source = ./configs/config.fish;

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "24.05";
  };
}
