# smartd option strings shared by all hosts, per device class.
# HDD:  temp -W 4,40,50, skip in standby, short test weekly + long twice a year.
# SSD:  temp -W 5,55,65, short test weekly.
# NVMe: temp -W 5,60,70 (runs hotter), short test weekly.
{
  hdd  = "-a -W 4,40,50 -n standby,15,q -s (S/../../7/02|L/(01|07)/01/./03)";
  ssd  = "-a -W 5,55,65 -s S/../../7/02";
  nvme = "-a -W 5,60,70 -s S/../../7/02";
}
