# Prometheus process_exporter — метрики CPU/RAM по процессам, скрейпит
# домашний сервер (192.168.1.100). Нужен, чтобы алерт по CPU называл
# конкретный процесс, а не только хост: на serverP залипший dockerd
# жёг ядро 7 часов, на pc-new — процесс 18.6 часов, и без этих метрик
# видно лишь "хост чем-то занят".
#
# Группировка по имени команды ({{.Comm}}), берём все процессы —
# так же, как настроено на сервере.
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

  networking.firewall.extraCommands = ''
    iptables -I INPUT -s 192.168.1.0/24 -p tcp --dport 9256 -j ACCEPT
  '';
}
