{ config, lib, pkgs, hostname, ... }:

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

  config = with lib; mkIf config.applications.hypr.enable (mkMerge [

    (mkIf (config.applications.hypr.apps.hypridle && hostname == "gibson") {
      services = {
        hypridle = with pkgs; {
          enable = true;
          lockCmd = "pidof hyprlock || hyprlock --immediate";
          afterSleepCmd = "sleep 1 && hyprctl dispatch dpms on; makoctl mode -s default; hyprctl dispatch -- exec undim_screen; qpwgraph -ma ${config.xdg.configHome}/qpwgraph/default.qpwgraph";
          listeners = [
            {
              timeout = 300;
              onTimeout = "hyprctl dispatch -- exec dim_screen;";
              onResume = "hyprctl dispatch -- exec undim_screen";
            }
            {
              timeout = 360;
              onTimeout = "loginctl lock-session";
            }
            {
              timeout = 600;
              onTimeout = "sleep 1 && hyprctl dispatch dpms off";
              onResume = "sleep 1 && hyprctl dispatch dpms on";
            }
            {
              timeout = 900;
              onTimeout = "systemctl hibernate";
            }
          ];
        };
      };
    })
  ]); # End mkMerge
}
