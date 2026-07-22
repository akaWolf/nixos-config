# pc-old disk list. Shared thresholds/schedules: modules/smartd-profiles.nix.
{ ... }:

let
  profiles = import ../../modules/smartd-profiles.nix;
in
{
  services.smartd.devices = [
    { device = "/dev/disk/by-id/ata-WDC_WD60EFPX-68C5ZN0_WD-WX12DA55TY07"; options = profiles.hdd; }
    { device = "/dev/disk/by-id/ata-ST2000NM0033-9ZM175_Z1X01V31";         options = profiles.hdd; }
    { device = "/dev/disk/by-id/ata-PLEXTOR_PX-128M5Pro_P02315110356";     options = profiles.ssd; }
    { device = "/dev/disk/by-id/ata-OCZ-VERTEX3_OCZ-3XW43PWU3QN3T44W";     options = profiles.ssd; }
  ];
}
