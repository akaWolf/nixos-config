# pc-old extra mounts + btrfs scrub.
# UUIDs identify physical disks on this host only.
{ ... }:

{
  fileSystems."/mnt/archive" = {
    device = "/dev/disk/by-uuid/c8c427d7-4b75-43cc-a955-1c3d17cb0340";
    fsType = "btrfs";
    options = [ "compress=zstd:1" "noatime" "nofail" ];
  };

  fileSystems."/mnt/seagate-data" = {
    device = "/dev/disk/by-uuid/F04847D648479A6C";
    fsType = "ntfs3";
    options = [ "ro" "nofail" "noauto" "x-systemd.automount" ];
  };

  fileSystems."/mnt/seagate-old" = {
    device = "/dev/disk/by-uuid/BA78EA2A78E9E55B";
    fsType = "ntfs3";
    options = [ "ro" "nofail" "noauto" "x-systemd.automount" ];
  };

  fileSystems."/mnt/plextor" = {
    device = "/dev/disk/by-uuid/F218AD6E18AD3291";
    fsType = "ntfs3";
    options = [
      "nofail"
      "noauto"
      "x-systemd.automount"
      "uid=1000"
      "gid=100"
    ];
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/mnt/archive" ];
  };
}
