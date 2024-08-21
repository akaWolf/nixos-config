{
  imports = [ <home-manager/nixos> ];

  users.users.akawolf.isNormalUser = true;

  home-manager.useUserPackages = true;

  home-manager.useGlobalPkgs = true;

  home-manager.users.akawolf = { pkgs, ... }: {
    home.packages = [ pkgs.atool pkgs.httpie pkgs.git ];
    programs.bash.enable = true;

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "24.05";
  };
}
