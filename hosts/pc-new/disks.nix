# pc-new extra mounts (NTFS read-only).
# UUIDs identify physical disks on this host only.
{ ... }:

{
  # Former /mnt/seagate-old (now physically attached to pc-new).
  fileSystems."/mnt/toshiba1" = {
    device = "/dev/disk/by-uuid/BA78EA2A78E9E55B";
    fsType = "ntfs3";
    options = [ "ro" "nofail" "noauto" "x-systemd.automount" ];
  };

  fileSystems."/mnt/toshiba2" = {
    device = "/dev/disk/by-uuid/560C81800C815BBD";
    fsType = "ntfs3";
    options = [ "ro" "nofail" "noauto" "x-systemd.automount" ];
  };
}
