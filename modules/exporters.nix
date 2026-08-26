# Prometheus exporters — system metrics for the home server's scraper
# (192.168.1.100). They bind wildcard addresses, so the firewall is what keeps
# them off the internet: both machines hold a globally routable IPv6 address on
# their LAN interface, and an interface-scoped rule would still admit external
# IPv6 arriving on that same interface. Hence a source-scoped rule instead, and
# no IPv6 counterpart at all — the scraper reaches us over IPv4 only.
{ lib, ... }:

{
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9100;
  };

  # smartctl_exporter — to compare SMART data presentation against scrutiny.
  services.prometheus.exporters.smartctl = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9633;
  };

  # Inserted at the head of nixos-fw: the chain ends in a log-refuse rule, so an
  # appended rule would never be reached. IPv4 only, by design.
  networking.firewall.extraCommands = ''
    iptables -I nixos-fw 1 -s 192.168.1.0/24 -p tcp -m multiport \
      --dports 9100,9256,9633 -j nixos-fw-accept
  '';

  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -s 192.168.1.0/24 -p tcp -m multiport \
      --dports 9100,9256,9633 -j nixos-fw-accept 2>/dev/null || true
  '';
}
