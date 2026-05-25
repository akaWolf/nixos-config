# AMD GPU health metrics for Prometheus via node_exporter textfile collector.
# Detects the "GPU disappeared from PCI bus" / "SMU firmware resume failed"
# class of bugs by exposing runtime_status, PCI enumeration, temperature, and
# resume-failure counters every minute.
{ config, lib, pkgs, ... }:

let
  textfileDir = "/var/lib/node-exporter/textfile_collector";

  checkScript = pkgs.writeShellScript "amdgpu-check" ''
    set -u
    out=${textfileDir}/amdgpu.prom
    tmp=$(${pkgs.coreutils}/bin/mktemp "$out.XXXXXX")
    trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT
    {
      echo "# HELP amdgpu_pci_present 1 if AMD GPU enumerated on PCI bus"
      echo "# TYPE amdgpu_pci_present gauge"
      found=0
      for d in /sys/bus/pci/devices/*; do
        ven=$(${pkgs.coreutils}/bin/cat "$d/vendor" 2>/dev/null) || continue
        cls=$(${pkgs.coreutils}/bin/cat "$d/class" 2>/dev/null) || continue
        [ "$ven" = "0x1002" ] || continue
        case "$cls" in 0x03????) ;; *) continue ;; esac
        bdf=$(${pkgs.coreutils}/bin/basename "$d")
        drv=$(${pkgs.coreutils}/bin/basename "$(${pkgs.coreutils}/bin/readlink "$d/driver" 2>/dev/null)" 2>/dev/null || echo none)
        echo "amdgpu_pci_present{bdf=\"$bdf\",driver=\"$drv\"} 1"
        found=1
      done
      [ "$found" -eq 0 ] && echo 'amdgpu_pci_present{bdf="none",driver="none"} 0'

      echo "# HELP amdgpu_runtime_status_info Current runtime PM status (1 for active status)"
      echo "# TYPE amdgpu_runtime_status_info gauge"
      for card in /sys/class/drm/card[0-9]*; do
        [ -d "$card/device" ] || continue
        [ "$(${pkgs.coreutils}/bin/cat "$card/device/vendor" 2>/dev/null)" = "0x1002" ] || continue
        bdf=$(${pkgs.coreutils}/bin/basename "$(${pkgs.coreutils}/bin/readlink "$card/device" 2>/dev/null)")
        status=$(${pkgs.coreutils}/bin/cat "$card/device/power/runtime_status" 2>/dev/null || echo unknown)
        echo "amdgpu_runtime_status_info{bdf=\"$bdf\",status=\"$status\"} 1"
      done

      echo "# HELP amdgpu_temp_celsius Edge temperature"
      echo "# TYPE amdgpu_temp_celsius gauge"
      for h in /sys/class/hwmon/hwmon*; do
        [ "$(${pkgs.coreutils}/bin/cat "$h/name" 2>/dev/null)" = "amdgpu" ] || continue
        t=$(${pkgs.coreutils}/bin/cat "$h/temp1_input" 2>/dev/null) || continue
        [ "$t" -gt 0 ] && echo "amdgpu_temp_celsius{hwmon=\"$(${pkgs.coreutils}/bin/basename "$h")\"} $((t/1000))"
      done

      echo "# HELP amdgpu_resume_failures_total Resume failures since boot (dmesg)"
      echo "# TYPE amdgpu_resume_failures_total counter"
      c=$(${pkgs.util-linux}/bin/dmesg 2>/dev/null | ${pkgs.gnugrep}/bin/grep -c 'amdgpu_device_ip_resume failed' || true)
      echo "amdgpu_resume_failures_total ${"$"}{c:-0}"
    } > "$tmp"
    ${pkgs.coreutils}/bin/chmod 644 "$tmp"
    ${pkgs.coreutils}/bin/mv "$tmp" "$out"
  '';
in {
  services.prometheus.exporters.node.extraFlags = [
    "--collector.textfile.directory=${textfileDir}"
  ];

  systemd.tmpfiles.rules = [
    "d ${textfileDir} 0755 node-exporter node-exporter -"
  ];

  systemd.services.amdgpu-monitor = {
    description = "AMD GPU health metrics for Prometheus";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${checkScript}";
    };
  };

  systemd.timers.amdgpu-monitor = {
    description = "Run amdgpu-monitor every minute";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "60s";
    };
  };
}
