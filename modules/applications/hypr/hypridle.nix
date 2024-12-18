{ config, lib, pkgs, inputs, hostname, ... }:

let

  scripts = rec {
    dim_screen = (import ./scripts/dim_screen.nix {inherit pkgs;});
    undim_screen = (import ./scripts/undim_screen.nix {inherit pkgs;});
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

  config = with lib; mkIf config.applications.hypr.enable (mkMerge [

    (mkIf (config.applications.hypr.apps.hypridle && hostname == "gibson") {
      services = {
        hypridle = with pkgs; {
          enable = true;
          settings = {
            general = {
              lock_cmd = "pidof hyprlock || hyprlock";
              before_sleep_cmd = "loginctl lock-session";
              after_sleep_cmd = "hyprctl --batch 'dispatch exec sleep 1; dispatch dpms on; dispatch exec makoctl mode -s default; dispatch exec openrgb -p ${config.xdg.configHome}/OpenRGB/MainBlue.orp; dispatch exec qpwgraph -ma ${config.xdg.configHome}/qpwgraph/default.qpwgraph; dispatch workspace name:2-web'; ${scripts.undim_screen.outPath}/bin/undim_screen;";
            };

            listener = [
              {
                timeout = 300;
                on-timeout = "${scripts.dim_screen.outPath}/bin/dim_screen";
                on-resume = "${scripts.undim_screen.outPath}/bin/undim_screen";
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
