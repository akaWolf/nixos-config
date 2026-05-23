# Prometheus node_exporter — exposes system metrics to the home server's
# Prometheus scraper (192.168.1.100). Bound on LAN, firewall opens 9100
# only for the home subnet (192.168.1.0/24). IPv6 is intentionally not
# opened — Prometheus reaches us over IPv4 only.
{ ... }:

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

  networking.firewall.extraCommands = ''
    iptables -I INPUT -s 192.168.1.0/24 -p tcp --dport 9100 -j ACCEPT
    iptables -I INPUT -s 192.168.1.0/24 -p tcp --dport 9633 -j ACCEPT
  '';
}
