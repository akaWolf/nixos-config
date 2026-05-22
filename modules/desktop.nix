# X11 + Qtile WM, audio, input. Shared desktop environment.
{ ... }:

{
  ##########################################################################
  # X11 / Qtile
  ##########################################################################
  services.xserver.enable = true;

  services.xserver.windowManager.qtile = {
    enable = true;
    extraPackages = python3Packages: with python3Packages; [
      qtile-extras
    ];
  };

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "intl-unicode,";
  services.xserver.xkb.options = "grp:caps_toggle,terminate:ctrl_alt_bksp,compose:rctrl";

  ##########################################################################
  # Sound (PipeWire)
  ##########################################################################
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Touchpad
  services.libinput.enable = true;
}
