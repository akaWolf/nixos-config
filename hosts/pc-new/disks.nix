# pc-new extra mounts (NTFS read-only).
# UUIDs identify physical disks on this host only.
#
# ntfs3 has no on-disk POSIX ownership, so it synthesises it from the mount
# options. Left at its defaults that means root:root with mode 0777 — every
# account on the machine can read both disks. uid/gid/umask move ownership to
# akawolf:users and drop "other" entirely, so access follows group membership:
# anyone outside "users" is locked out. There is no way around it either —
# /dev/sda* is root:disk 0660 with an empty "disk" group, and udisks treats
# these as internal drives (/sys/block/sda/removable = 0), whose mount action
# needs admin auth.
{ ... }:

{
  # umask above does not cover the volume's own root inode — ntfs3 leaves that
  # one 0777 regardless, so an outsider could still list the top-level file
  # names (not open them). /mnt itself is therefore the boundary: 0750
  # root:users means non-members cannot traverse into the mount points at all.
  # Nothing else in this config refers to /mnt, and /mnt/tmp is empty.
  systemd.tmpfiles.rules = [ "d /mnt 0750 root users -" ];

  # Former /mnt/seagate-old (now physically attached to pc-new).
  fileSystems."/mnt/toshiba1" = {
    device = "/dev/disk/by-uuid/BA78EA2A78E9E55B";
    fsType = "ntfs3";
    options = [
      "ro"
      "nofail"
      "noauto"
      "x-systemd.automount"
      "uid=1000"
      "gid=100"
      "umask=027"
    ];
  };

  fileSystems."/mnt/toshiba2" = {
    device = "/dev/disk/by-uuid/560C81800C815BBD";
    fsType = "ntfs3";
    options = [
      "ro"
      "nofail"
      "noauto"
      "x-systemd.automount"
      "uid=1000"
      "gid=100"
      "umask=027"
    ];
  };
}
