{
  lib,
  pkgs,
  vars,
  hostname,
  ...
}:
let
  hyprConfig = vars.flakeSource + "/hosts/${hostname}/applications/hypr/hyprland.lua";
in
{
  config =
    with lib;
    mkIf pkgs.stdenv.hostPlatform.isLinux {
      # Shared hyprland configuration
      xdg.configFile."hypr/${hostname}.lua".source = hyprConfig;

      wayland.windowManager.hyprland = {
        enable = true;
        sourceFirst = false;
        configType = "lua";

        systemd = {
          enable = true;
          variables = [ "--all" ];
        };

        extraConfig = ''
          local WS = {
            WS1 = "1-main",
            WS2 = "2-web",
            WS3 = "3-game",
            WS4 = "4-h4x0r",
            WS5 = "5-social",
            WS6 = "6-media",
            WS7 = "7-passwd",
            WS8 = "8-ext1",
            WS9 = "9-ext2",
            WS0 = "10-ext3",
          }

          hl.config({
            input = {
              kb_file = "",
              kb_layout = "us",
              kb_variant = "",
              kb_model = "",
              kb_options = "caps:escape",
              kb_rules = "",
              follow_mouse = 1,

              touchpad = {
                natural_scroll = false,
              },

              sensitivity = 0,
            },

            general = {
              gaps_in = 5,
              gaps_out = 10,
              border_size = 1,
              col = {
                active_border = 0xffbd93f9,
                inactive_border = 0xff44475a,
              },
              layout = "scrolling",
            },

            cursor = {
              default_monitor = "DP-2",
              inactive_timeout = 5,
            },

            decoration = {
              rounding = 4,
              blur = {
                enabled = true,
                size = 5,
                passes = 1,
                new_optimizations = true,
              },
            },

            animations = {
              enabled = true,
            },

            misc = {
              mouse_move_enables_dpms = true,
              key_press_enables_dpms = true,
              force_default_wallpaper = 0,
              allow_session_lock_restore = true,
              initial_workspace_tracking = 0,
            },

            group = {
              groupbar = {
                render_titles = false,
                col = {
                  active = 0xffbd93f9,
                  inactive = 0xff44475a,
                  locked_active = 0xffbd93f9,
                  locked_inactive = 0xff44475a,
                },
                height = 1,
              },

              col = {
                border_active = 0xffbd93f9,
                border_inactive = 0xff44475a,
                border_locked_active = 0xffbd93f9,
                border_locked_inactive = 0xff44475a,
              },
            },

            binds = {
              workspace_center_on = 1,
            },

            xwayland = {
              enabled = true,
            },
          })

          hl.animation({ leaf = "windows",    enabled = true, speed = 2, bezier = "default", style = "popin" })
          hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "default", style = "popin" })
          hl.animation({ leaf = "border",     enabled = true, speed = 6, bezier = "default" })
          hl.animation({ leaf = "fade",       enabled = true, speed = 6, bezier = "default" })
          hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default", style = "fade" })

          require("${hostname}")(WS)
        '';
      };
    };
}
