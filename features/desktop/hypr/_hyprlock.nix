{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.home.hyprlock;

  # Shared by every monitor's background
  background = {
    color = "rgba(0, 0, 0, 1)";
    blur_size = 0;
    blur_passes = 0;
    noise = 0.0;
    contrast = 0.0;
    brightness = 0.0;
    vibrancy = 0.0;
    vibrancy_darkness = 0.0;
  };
in
{
  options.features.home.hyprlock = {
    primaryMonitor = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "DP-1";
      description = "The main monitor, which shows the clock and password field; empty shows them on every monitor.";
    };

    wallpapers = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ DP-1 = "''${config.xdg.configHome}/Wallpapers/lock.png"; }'';
      description = "An image for each monitor's background; none gives every monitor a black one.";
    };
  };

  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    programs.hyprlock = {
      enable = true;

      settings = {
        general = {
          hide_cursor = true;
          ignore_empty_input = true;
        };

        background =
          if cfg.wallpapers == { } then
            [ (background // { monitor = ""; }) ]
          else
            lib.mapAttrsToList (monitor: path: background // { inherit monitor path; }) cfg.wallpapers;

        input-field = [
          {
            monitor = cfg.primaryMonitor;
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
            monitor = cfg.primaryMonitor;
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
            monitor = cfg.primaryMonitor;
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
}
