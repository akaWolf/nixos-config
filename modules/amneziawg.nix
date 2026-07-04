# AmneziaWG VPN client — DPI-obfuscated WireGuard fork.
#
# Deployment model:
#   1. Enable services.amneziawg + list interface names per host.
#   2. Place /etc/amnezia/amneziawg/<iface>.conf (root:root mode 600) with
#      private key, Endpoint, AllowedIPs, and AmneziaWG obfuscation fields
#      (Jc, Jmin, Jmax, S1, S2, H1..H4). Generate via Amnezia GUI client
#      or get from your AmneziaWG server.
#   3. Service awg-quick-<iface>.service brings the tunnel up at boot
#      (and only fires if the .conf file exists — safe to enable without it).
#
# Uses userspace amneziawg-go (no out-of-tree kernel module needed).
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.amneziawg;
in {
  options.services.amneziawg = {
    enable = mkEnableOption "AmneziaWG VPN client tools";

    interfaces = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "wg0" ];
      description = ''
        Interface names to bring up at boot. Each requires a corresponding
        /etc/amnezia/amneziawg/<name>.conf file (not managed by Nix).
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ amneziawg-tools amneziawg-go ];

    systemd.services = listToAttrs (map (iface: nameValuePair "awg-quick-${iface}" {
      description = "AmneziaWG tunnel for ${iface}";
      after = [ "network-online.target" "nss-lookup.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      unitConfig.ConditionPathExists = "/etc/amnezia/amneziawg/${iface}.conf";

      serviceConfig = {
        # Tie the unit's lifetime to the userspace amneziawg-go daemon: awg-quick
        # up brings the tunnel up (daemonizes amneziawg-go), then we block while
        # that process lives. If it dies (crash → wg0 silently disappears, as it
        # did once), exit non-zero so Restart=always runs ExecStop (down) and then
        # re-runs the whole pipeline. Watch the process, not the socket — a crash
        # can leave a stale socket behind.
        Type = "simple";
        ExecStart = pkgs.writeShellScript "awg-quick-up-watch-${iface}" ''
          set -e
          ${pkgs.amneziawg-tools}/bin/awg-quick up ${iface}
          set +e
          while ${pkgs.procps}/bin/pgrep -f "amneziawg-go.*${iface}" >/dev/null 2>&1; do
            sleep 5
          done
          echo "amneziawg-go for ${iface} died — triggering restart" >&2
          exit 1
        '';
        ExecStop = "${pkgs.amneziawg-tools}/bin/awg-quick down ${iface}";
        Restart = "always";
        RestartSec = "3";
      };

      path = with pkgs; [ amneziawg-tools amneziawg-go iproute2 iptables procps ];
    }) cfg.interfaces);
  };
}
