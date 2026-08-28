# Host: pc-old (akaWolf-PC-Old) — hardware-specific config.
{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    ./smartd.nix
  ];

  networking.hostName = "akaWolf-PC-Old";

  # Motherboard SuperIO sensors (ITE IT8728F) — driver isn't auto-loaded,
  # and ACPI claims the chip's I/O ports unless told to back off.
  boot.kernelModules = [ "it87" ];
  boot.kernelParams = [ "acpi_enforce_resources=lax" "amdgpu.runpm=0" ];

  # Polaris card needs the AMD GPU health watchdog.
  my.amdgpu-monitor.enable = true;

  # Collector strips "/dev/" prefix internally — by-id paths break (see
  # smart_support:false in early debug). Identity in scrutiny comes from the
  # disk serial, so this list only has to name every disk; which letter lands
  # on which drive does not matter and is not stable — the four have already
  # reshuffled across reboots, so no letter is annotated with a model here.
  # Disks on this host: OCZ-VERTEX3 (system), WD60EFPX (archive),
  # ST2000NM0033, PLEXTOR PX-128M5Pro (windows).
  my.scrutiny-collector.devices = [
    { device = "/dev/sda"; type = "sat"; }
    { device = "/dev/sdb"; type = "sat"; }
    { device = "/dev/sdc"; type = "sat"; }
    { device = "/dev/sdd"; type = "sat"; }
  ];

  # Receiving end of pc-new's netconsole (see its host config). The lines land
  # in this machine's journal tagged netconsole-pcnew, so they rotate with
  # everything else instead of growing a file nobody prunes:
  #   journalctl -t netconsole-pcnew
  systemd.services.netconsole-receiver = {
    description = "Collect kernel console messages from pc-new";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "netconsole-receiver" ''
        ${pkgs.socat}/bin/socat -u UDP-RECV:6666,reuseaddr - \
          | ${pkgs.systemd}/bin/systemd-cat -t netconsole-pcnew
      '';
      DynamicUser = true;
      Restart = "always";
      RestartSec = 5;
    };
  };

  networking.firewall.extraCommands = ''
    iptables -I nixos-fw 1 -s 192.168.1.0/24 -p udp --dport 6666 -j nixos-fw-accept
  '';

  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -s 192.168.1.0/24 -p udp --dport 6666 -j nixos-fw-accept 2>/dev/null || true
  '';

  # First NixOS version installed on this machine. Do NOT change.
  system.stateVersion = "24.05";
}
