# pc-old disk list + per-device temperature thresholds.
# Disks: WD Red 6TB, Seagate Constellation 2TB, Plextor + OCZ SSDs.
{ ... }:

{
  services.smartd.devices = [
    # HDD: -W 4,40,50; short weekly + long twice a year
    { device = "/dev/disk/by-id/ata-WDC_WD60EFPX-68C5ZN0_WD-WX12DA55TY07";
      options = "-a -W 4,40,50 -n standby,15,q -s (S/../../7/02|L/(01|07)/01/./03)"; }
    { device = "/dev/disk/by-id/ata-ST2000NM0033-9ZM175_Z1X01V31";
      options = "-a -W 4,40,50 -n standby,15,q -s (S/../../7/02|L/(01|07)/01/./03)"; }
    # SSD: -W 5,55,65; short weekly only
    { device = "/dev/disk/by-id/ata-PLEXTOR_PX-128M5Pro_P02315110356";
      options = "-a -W 5,55,65 -s S/../../7/02"; }
    { device = "/dev/disk/by-id/ata-OCZ-VERTEX3_OCZ-3XW43PWU3QN3T44W";
      options = "-a -W 5,55,65 -s S/../../7/02"; }
  ];
}
