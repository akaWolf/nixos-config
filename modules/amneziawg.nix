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
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.amneziawg-tools}/bin/awg-quick up ${iface}";
        ExecStop  = "${pkgs.amneziawg-tools}/bin/awg-quick down ${iface}";
      };

      path = with pkgs; [ amneziawg-tools amneziawg-go iproute2 iptables ];
    }) cfg.interfaces);
  };
}
