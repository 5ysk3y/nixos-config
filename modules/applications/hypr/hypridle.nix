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
            general = {
              lock_cmd = "pidof hyprlock || hyprlock --immediate";
              after_sleep_cmd = "sleep 1; pkill qpwgraph; hyprctl --batch 'dispatch dpms on; dispatch exec makoctl mode -s default; dispatch exec undim_screen; dispatch exec qpwgraph -ma ${config.xdg.configHome}/qpwgraph/default.qpwgraph; dispatch exec openrgb -p ${config.xdg.configHome}/OpenRGB/MainBlue.orp'";
            };

            listener = [
              {
                timeout = 300;
                on-timeout = "hyprctl dispatch -- exec dim_screen;";
                on-resume = "hyprctl dispatch -- exec undim_screen";
              }
              {
                timeout = 360;
                on-timeout = "loginctl lock-session";
              }
              {
                timeout = 600;
                on-timeout = "sleep 1 && hyprctl dispatch dpms off";
                on-resume = "sleep 1 && hyprctl dispatch dpms on";
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
