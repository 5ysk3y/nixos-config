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
          settings = {
            lockCmd = "pidof hyprlock || hyprlock --immediate";
            afterSleepCmd = "sleep 1; pkill qpwgraph; hyprctl --batch 'dispatch dpms on; dispatch exec makoctl mode -s default; dispatch exec undim_screen; dispatch exec qpwgraph -ma ${config.xdg.configHome}/qpwgraph/default.qpwgraph; dispatch exec openrgb -p ${config.xdg.configHome}/OpenRGB/MainBlue.orp'";
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
      };
    })
  ]); # End mkMerge
}
