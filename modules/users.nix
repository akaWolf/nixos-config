# User accounts, shell default, sudo policy.
{ pkgs, ... }:

{
  users.defaultUserShell = pkgs.fish;

  # Passwordless sudo for the wheel group.
  security.sudo.wheelNeedsPassword = false;

  # Allow akawolf to run smartctl without password (used by remote SMART monitor).
  security.sudo.extraRules = [{
    users = [ "akawolf" ];
    commands = [{
      command = "${pkgs.smartmontools}/bin/smartctl";
      options = [ "NOPASSWD" ];
    }];
  }];

  users.users.akawolf = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" "reader" "dialout" "input" ];

    openssh.authorizedKeys.keys = [
      # Personal login key.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC1UZUcjfpcxoG89bVvCM5XxDdgnd5bkkM8MaijEI9oT akawolf0@gmail.com"
      # Restricted monitor key: forced command, no shell/pty/forwarding.
      # Client passes "/dev/sdX" as ssh command; sshd executes only the wrapped smartctl.
      ''restrict,command="sudo /run/current-system/sw/bin/smartctl --json -a $SSH_ORIGINAL_COMMAND" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFqtIwoJ94cyvT0nHgTI2ElSD5F2GyYiDEedh/pVYZ1u smart-monitor@akawolf.org''
    ];
  };
}
