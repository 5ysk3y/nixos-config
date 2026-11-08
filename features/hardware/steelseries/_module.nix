# SteelSeries Aerox 5 mice: lets rivalcfg reach them without root, for
# Waybar's custom/steelseries battery and colour scripts
# (features/desktop/waybar/_scripts) and from the command line
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.rivalcfg ];

  services.udev.extraRules = ''
    # SteelSeries Aerox 5
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1850", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1850", MODE="0666"

    # SteelSeries Aerox 5 Wireless (wired mode)
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1854", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1854", MODE="0666"

    # SteelSeries Aerox 5 Wireless (2.4 GHz wireless mode)
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1852", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1852", MODE="0666"
  '';
}
