# Smart-card / serial-reader support. Harmless on hosts without a reader.
{ ... }:

{
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666"
  '';

  # PCSC-Lite daemon — enable per-host if a reader is attached.
  # services.pcscd = {
  #   enable = true;
  #   plugins = [ pkgs.ccid ];
  # };
}
