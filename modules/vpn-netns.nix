{ config, lib, pkgs, ... }:

let
  sudo = "/run/wrappers/bin/sudo";

  # Runs as root inside `ip netns exec`, which gives it a private mount
  # namespace. glibc asks nscd whenever its socket is reachable, and nscd
  # sits in the default netns and uses the LAN resolver, so DNS bypassed the
  # tunnel and /etc/netns/ns_vpn/resolv.conf went unused. An empty tmpfs over
  # /run/nscd sends glibc to that resolv.conf.
  enter = pkgs.writeShellScript "vpn-enter" ''
    if [ -d /run/nscd ]; then
      ${pkgs.util-linux}/bin/mount -t tmpfs -o size=4k,mode=0755 nscd-hidden /run/nscd || exit 1
    fi
    exec ${sudo} -E -H -u akawolf "$@"
  '';
in
{
  systemd.services."netns-ns_vpn" = {
    description = "Network namespace ns_vpn (used by wg0 + vpn wrapper)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    before = [ "awg-quick-wg0.service" ];
    # Never recreate the namespace on a switch: `ip netns delete` + `add`
    # strands whatever already runs inside in an orphaned copy without wg0,
    # and stopping this unit also stops every unit that Requires= it. A changed
    # unit (a new iproute2, say) takes effect on the next boot instead.
    restartIfChanged = false;
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
      exec ${sudo} ${pkgs.iproute2}/bin/ip netns exec ns_vpn ${enter} "$@"
    '')
  ];

  security.sudo.extraRules = [{
    users = [ "akawolf" ];
    commands = [{
      command = "${pkgs.iproute2}/bin/ip netns exec ns_vpn ${enter} *";
      options = [ "NOPASSWD" ];
    }];
  }];
}
