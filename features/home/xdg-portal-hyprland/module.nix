{ config, pkgs, ... }:
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
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk # Added as per https://wiki.hyprland.org/Hypr-Ecosystem/xdg-desktop-portal-hyprland/
      ];
      configPackages = [ pkgs.hyprland ];
    };
  };
}
