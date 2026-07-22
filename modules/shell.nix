# Fish shell (system-level enablement; per-user config via home-manager).
{ pkgs, ... }:

{
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    babelfish          # sh -> fish env translation (config.fish sources hm vars with it)
    fishPlugins.pure   # prompt
  ];
}
