# pc-new disk list. Shared thresholds/schedules: modules/smartd-profiles.nix.
{ ... }:

let
  profiles = import ../../modules/smartd-profiles.nix;
in
{
  services.smartd.devices = [
    { device = "/dev/disk/by-id/ata-TOSHIBA_HDWD130_79TDEYEAS";                  options = profiles.hdd;  }
    { device = "/dev/disk/by-id/nvme-GIGABYTE_GP-ASM2NE6200TTTD_SN200908901564"; options = profiles.nvme; }
  ];
}
