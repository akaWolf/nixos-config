# User accounts, shell default, sudo policy.
{ pkgs, ... }:

{
  users.defaultUserShell = pkgs.fish;

  # Passwordless sudo for the wheel group.
  security.sudo.wheelNeedsPassword = false;

  users.users.akawolf = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" "reader" "dialout" "input" ];

    openssh.authorizedKeys.keys = [
      # Personal login key.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC1UZUcjfpcxoG89bVvCM5XxDdgnd5bkkM8MaijEI9oT akawolf0@gmail.com"
    ];
  };
}
