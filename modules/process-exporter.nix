# Prometheus process_exporter — per-process CPU/RAM metrics, scraped by the
# home server (192.168.1.100). Exists so a CPU alert can name the offending
# process instead of just the host: a stuck dockerd once burned a core for
# 7 hours on the server, and pc-new ran one hot process for 18.6 hours —
# without these metrics all you see is "the host is busy".
#
# Group by command name ({{.Comm}}), take every process — same setup as on
# the server.
{ ... }:

{
  services.prometheus.exporters.process = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9256;
    settings.process_names = [
      { name = "{{.Comm}}"; cmdline = [ ".+" ]; }
    ];
  };
}
