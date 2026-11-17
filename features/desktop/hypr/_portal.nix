{
  pkgs,
  ...
}:

{
  xdg = {
    enable = true;
    portal = {
      enable = true;
      config = {
        hyprland = {
          default = [
            "hyprland"
            "gtk"
          ];
        };
      };
      # xdg-desktop-portal-hyprland comes from the Hyprland module
      # (wayland.windowManager.hyprland.portalPackage); gtk handles the
      # interfaces it doesn't, e.g. the file chooser
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}
