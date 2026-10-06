# pc-new extra mounts. There are none at the moment: the TOSHIBA HDWD130
# behind /mnt/toshiba1 and /mnt/toshiba2 failed SMART and was retired on
# 2026-10-06, after its contents were archived on pc-old. It is still cabled,
# so it comes back as a block device after a reboot, but nothing mounts or
# polls it any more.
{ ... }:

{
  # Kept from the ntfs mounts: /mnt stays 0750 root:users, so accounts outside
  # "users" cannot traverse into whatever gets mounted under it next.
  systemd.tmpfiles.rules = [ "d /mnt 0750 root users -" ];
}
