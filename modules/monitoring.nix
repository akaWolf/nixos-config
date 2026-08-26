# Disk health monitoring: smartd + email delivery via msmtp.
# Per-device thresholds and the device list live in hosts/<host>/smartd.nix.
{ pkgs, ... }:

{
  ##########################################################################
  # SMTP relay (Gmail) for system mail. Password in /var/lib/secrets/msmtp-pass.
  ##########################################################################
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    accounts.default = {
      auth = true;
      tls = true;
      host = "smtp.gmail.com";
      port = 587;
      from = "akawolf.server@gmail.com";
      user = "akawolf.server@gmail.com";
      # Full path to cat: msmtp runs passwordeval via /bin/sh with a minimal
      # PATH that does not include /run/current-system/sw/bin.
      passwordeval = "${pkgs.coreutils}/bin/cat /var/lib/secrets/msmtp-pass";
    };
  };

  ##########################################################################
  # smartd — common machinery. Devices + -W thresholds are per-host.
  ##########################################################################
  services.smartd = {
    enable = true;
    autodetect = false; # device list is explicit, per-host
    # No wall(1) broadcasts: they land in every terminal registered in utmp,
    # including every screen window, and a failing disk warns every 30 minutes.
    # Mail still goes out, and the metrics reach prometheus/scrutiny anyway.
    notifications.wall.enable = false;

    notifications.mail = {
      enable = true;
      recipient = "akawolf0@gmail.com";
      sender = "smartd@akawolf";
      mailer = "/run/wrappers/bin/sendmail";
    };
  };
}
