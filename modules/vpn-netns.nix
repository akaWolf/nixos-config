{ config, lib, pkgs, ... }:

let
  sudo = "/run/wrappers/bin/sudo";
in
{
  systemd.services."netns-ns_vpn" = {
    description = "Network namespace ns_vpn (used by wg0 + vpn wrapper)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    before = [ "awg-quick-wg0.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip netns add ns_vpn";
      ExecStop = "${pkgs.iproute2}/bin/ip netns delete ns_vpn";
    };
  };

  systemd.services."awg-quick-wg0" = {
    after = [ "netns-ns_vpn.service" ];
    requires = [ "netns-ns_vpn.service" ];
  };

  environment.etc."netns/ns_vpn/resolv.conf".text = ''
    nameserver 1.1.1.1
    nameserver 2606:4700:4700::1111
  '';

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "vpn" ''
      exec ${sudo} ${pkgs.iproute2}/bin/ip netns exec ns_vpn ${sudo} -E -H -u akawolf "$@"
    '')
  ];

  security.sudo.extraRules = [{
    users = [ "akawolf" ];
    commands = [{
      command = "${pkgs.iproute2}/bin/ip netns exec ns_vpn ${sudo} -E -H -u akawolf *";
      options = [ "NOPASSWD" ];
    }];
  }];
}
