# System-level packages only. User tools live in home/akawolf.nix.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    babelfish          # fish helper (system shell)
    fishPlugins.pure   # prompt
    ntfs3g             # NTFS filesystem driver
  ];
}
