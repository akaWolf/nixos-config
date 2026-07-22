# Prometheus exporters — system metrics for the home server's scraper
# (192.168.1.100). Listen on 0.0.0.0. The machine firewall is disabled
# (common.nix), so nothing gates these ports beyond the home NAT.
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
}
