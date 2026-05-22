# Smart-card / serial-reader support. Harmless on hosts without a reader.
{ ... }:

{
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666"
    ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="pcspkr", MODE="0660", GROUP="input"
  '';

  # PCSC-Lite daemon — enable per-host if a reader is attached.
  # services.pcscd = {
  #   enable = true;
  #   plugins = [ pkgs.ccid ];
  # };
}
