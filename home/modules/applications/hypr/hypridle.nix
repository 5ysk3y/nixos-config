{
  config,
  lib,
  pkgs,
  inputs,
  hostname,
  ...
}:
let
  scripts = rec {
    dim_screen = import ./scripts/dim_screen.nix { inherit pkgs; };
    undim_screen = import ./scripts/undim_screen.nix { inherit pkgs; };
  };
in
{
  options = with lib; {
    applications = {
      hypr = {
        apps = {
          hypridle = mkEnableOption "Enabled Hypridle with custom configs";
        };
      };
    };
  };

  config =
    with lib;
    mkIf config.applications.hypr.enable (mkMerge [
      (mkIf (config.applications.hypr.apps.hypridle && hostname == "gibson") {
        services = {
          hypridle = with pkgs; {
            enable = true;
            settings = {
              general = {
                lock_cmd = "pidof hyprlock || hyprlock";
                after_sleep_cmd = "hyprctl --batch 'dispatch exec makoctl mode -s default; dispatch exec sleep 1; dispatch dpms on'; wtype -k escape; openrgb -p ${config.xdg.configHome}/OpenRGB/MainBlue.orp;";
              };

              listener = [
                {
                  timeout = 300;
                  on-timeout = "dim -d 0";
                }
                {
                  timeout = 360;
                  on-timeout = "loginctl lock-session";
                }
                {
                  timeout = 600;
                  on-timeout = "sleep 1 && hyprctl dispatch dpms off";
                  on-resume = "sleep 1 && hyprctl --batch 'dispatch dpms on'";
                }
                {
                  timeout = 900;
                  on-timeout = "systemctl hibernate";
                }
              ];
            };
          };
        };
      })
    ]); # End mkMerge
}
