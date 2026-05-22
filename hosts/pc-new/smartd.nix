# pc-new disk list + per-device temperature thresholds.
# Disks: TOSHIBA HDWD130 (HDD), GIGABYTE NVMe SSD.
{ ... }:

{
  services.smartd.devices = [
    # HDD: -W 4,40,50; short weekly + long twice a year
    { device = "/dev/disk/by-id/ata-TOSHIBA_HDWD130_79TDEYEAS";
      options = "-a -W 4,40,50 -n standby,15,q -s (S/../../7/02|L/(01|07)/01/./03)"; }
    # NVMe SSD: -W 5,60,70 (NVMe runs warmer); short weekly
    { device = "/dev/disk/by-id/nvme-GIGABYTE_GP-ASM2NE6200TTTD_SN200908901564";
      options = "-a -W 5,60,70 -s S/../../7/02"; }
  ];
}
