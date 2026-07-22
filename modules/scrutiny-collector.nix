# SMART metrics collector — pushes smartctl data to scrutiny-web hub.
# Hub runs on the home server (192.168.1.100:8091) over LAN.
# Per-device list lives in hosts/<host>/default.nix; smartd thresholds
# in hosts/<host>/smartd.nix remain the source of truth for alerts.
{ pkgs, config, lib, ... }:

let
  cfg = config.my.scrutiny-collector;

  # Pinned version of the upstream collector. We override the nixpkgs
  # package because nixpkgs ships v0.8.1, but our scrutiny-web hub is
  # v0.9.x — v0.9 collectors generate scrutiny_uuid client-side, v0.8
  # collectors don't, and the new hub rejects v0.8 registrations.
  scrutiny-collector = pkgs.scrutiny-collector.overrideAttrs (_: {
    inherit (cfg) version;
    src = pkgs.fetchFromGitHub {
      owner = "AnalogJ";
      repo = "scrutiny";
      rev = "v${cfg.version}";
      hash = cfg.srcHash;
    };
    vendorHash = cfg.vendorHash;
  });

  collectorConfig = pkgs.writeText "scrutiny-collector.yaml" (lib.concatStringsSep "\n" ([
    "version: 1"
    "host:"
    "  id: ${lib.toLower config.networking.hostName}"
    "api:"
    "  endpoint: http://192.168.1.100:8091"
    "devices:"
  ] ++ map (d: "  - device: ${d.device}\n    type: ${d.type}") cfg.devices));
in
{
  options.my.scrutiny-collector = {
    version = lib.mkOption {
      type = lib.types.str;
      default = "0.9.2";
      description = "Upstream scrutiny release tag to track (without leading v).";
    };
    srcHash = lib.mkOption {
      type = lib.types.str;
      default = "sha256-ZQHTwJZBOYJ2De0CmyxXc4Fb2Vt+jKg+YpDDZhSt+cg=";
      description = "fetchFromGitHub hash for the pinned source tree.";
    };
    vendorHash = lib.mkOption {
      type = lib.types.str;
      default = "sha256-Em8k2AFoZv4TD4HFkkNIdyPj7IBOFiUIKffkifWfZFY=";
      description = "buildGoModule vendor hash for the pinned source.";
    };
    devices = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          device = lib.mkOption { type = lib.types.str; example = "/dev/sda"; };
          type   = lib.mkOption { type = lib.types.str; example = "sat"; };
        };
      });
      default = [];
      description = "Disks to monitor, with smartctl -d <type>.";
    };
  };

  config = {
    systemd.services.scrutiny-collector = {
      description = "Scrutiny collector — push SMART to hub";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.smartmontools ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${scrutiny-collector}/bin/scrutiny-collector-metrics run --config ${collectorConfig}";
      };
    };

    systemd.timers.scrutiny-collector = {
      description = "Scrutiny collector hourly";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "3min";
        OnUnitActiveSec = "1h";
        Persistent = true;
      };
    };
  };
}
