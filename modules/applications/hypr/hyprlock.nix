{ config, lib, pkgs, hostname, ... }:

{

  options = with lib; {
    applications = {
      hypr = {
        apps = {
          hyprlock = mkEnableOption "Enabled Hyprlock with custom configs";
        };
      };
    };
  };

  config = with lib; mkIf config.applications.hypr.enable (mkMerge [

    (mkIf (config.applications.hypr.apps.hyprlock) {
      programs = {
        hyprlock = {
          enable = true;
          settings = {
            general = {
              grace = 30;
              hide_cursor = true;
            };
          };
        };
      };
    })

    (mkIf (config.applications.hypr.apps.hyprlock && hostname == "gibson") {
      programs = {
        hyprlock = {
          settings = {
            background = [
              {
                monitor = "DP-1";
                path = "${config.xdg.configHome}/Wallpapers/hex_lockscreen_middle.png";
                color = "rgba(0, 0, 0, 1)";
                blur_size = 0;
                blur_passes = 0;
                noise = 0.0;
                contrast = 0.0;
                brightness = 0.0;
                vibrancy = 0.0;
                vibrancy_darkness = 0.0;
              }
              {
                monitor = "DP-2";
                path = "${config.xdg.configHome}/Wallpapers/hex_lockscreen_left.png";
                color = "rgba(0, 0, 0, 1)";
                blur_size = 0;
                blur_passes = 0;
                noise = 0.0;
                contrast = 0.0;
                brightness = 0.0;
                vibrancy = 0.0;
                vibrancy_darkness = 0.0;
              }
              {
                monitor = "HDMI-A-2";
                path = "${config.xdg.configHome}/Wallpapers/hex_lockscreen_right.png";
                color = "rgba(0, 0, 0, 1)";
                blur_size = 0;
                blur_passes = 0;
                noise = 0.0;
                contrast = 0.0;
                brightness = 0.0;
                vibrancy = 0.0;
                vibrancy_darkness = 0.0;
              }
            ];
          };
        };
      };
    })

    (mkIf (config.applications.hypr.apps.hyprlock && hostname == "gibson") {
      programs = {
        hyprlock = {
          settings = {
            input-field = [
              {
                monitor = "DP-1";
                fade_on_empty = false;
                dots_center = true;
                size = "250, 50";
                outer_color = "rgb(255, 184, 108)";
                inner_color = "rgb(0, 0, 0)";
                font_color = "rgb(255, 255, 255)";
              }
            ];

            label = [
              {
                monitor = "DP-1";
                text = "cmd[update:10000] echo \"$(date +'%R')\"";
                font_family = "Hack";
                position = "0, 80";
                halign = "center";
                valign = "center";
                color = "rgba(255, 255, 255, 1)";
                font_size = 60;

                shadow_passes = 1;
                shadow_size = 6;
                shadow_color = "rgba(255, 184, 108, 0.5)";
                shadow_boost = 1.6;
              }
              {
                monitor = "DP-1";
                text = "$FAIL";
                font_family = "Hack";
                position = "0, 200";
                halign = "center";
                valign = "center";
                color = "rgba(255, 255, 255, 1)";
                font_size = 20;

                shadow_passes = 1;
                shadow_size = 6;
                shadow_color = "rgba(255, 184, 108, 0.5)";
                shadow_boost = 1.6;
              }
            ];
          };
        };
      };
    })
  ]);
}
