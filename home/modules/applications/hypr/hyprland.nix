{
  config,
  lib,
  pkgs,
  inputs,
  vars,
  hostname,
  ...
}:
let
  scripts = rec {
    undim_screen = import ./scripts/undim_screen.nix { inherit pkgs; };
  };
  hyprConfig = vars.flakeSource + "/hosts/${hostname}/applications/hypr/hyprland.conf";
in
{
  options = with lib; {
    applications = {
      hypr = {
        enable = mkEnableOption "Enables the Hypr* suite off apps with custom configs";
        apps = {
          hyprland = mkEnableOption "Enables Hyprland with custom configs";
        };
      };
    };
  };

  config =
    with lib;
    mkIf (config.applications.hypr.enable && pkgs.stdenv.hostPlatform.isLinux) {
      # Shared hyprland configuration

      xdg.configFile."hypr/${hostname}.conf".source = hyprConfig;

      wayland.windowManager.hyprland = {
        enable = true;
        sourceFirst = false;
        systemd = {
          enable = true;
          variables = [
            "--all"
          ];
        };
        extraConfig = ''
          input {
              kb_file =
              kb_layout = us
              kb_variant =
              kb_model =
              kb_options = caps:escape
              kb_rules =

              follow_mouse = 1

              touchpad {
                  natural_scroll = no
              }

              sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
          }

          general {
              gaps_in = 5
              gaps_out = 10
              border_size = 1
              col.active_border = 0xffbd93f9
              col.inactive_border = 0xff44475a

              layout = master
          }

          cursor {
            default_monitor = DP-2
            inactive_timeout = 5
          }

          decoration {
              rounding = 4
              blur {
                  enabled = 1
                  size = 5 # minimum 1
                  passes = 1 # minimum 1
                  new_optimizations = 1
              }
          }

          animations {
              enabled = 1
              animation = windows,1,2,default,popin
              animation = windowsOut,1,2,default,popin
              animation = border,1,6,default
              animation = fade,1,6,default
              animation = workspaces,1,6,default,fade
          }

          master {
              new_status = master
              new_on_top = true
          }

          misc {
              mouse_move_enables_dpms = true
              key_press_enables_dpms = true
              force_default_wallpaper = 0
              vrr = true
              vfr = true
              allow_session_lock_restore = 1
          }

          group {
                groupbar {
                  render_titles = false
                  col.active = 0xffbd93f9
                  col.inactive = 0xff44475a
                  col.locked_active = 0xffbd93f9
                  col.locked_inactive = 0xff44475a
                  height = 1
                }
          col.border_active = 0xffbd93f9
          col.border_inactive = 0xff44475a
          col.border_locked_active = 0xffbd93f9
          col.border_locked_inactive = 0xff44475a
          }

          binds {
                workspace_center_on = 1
          }

          xwayland {
                  enabled = true
          }

          $WS1 = 1-main
          $WS2 = 2-web
          $WS3 = 3-game
          $WS4 = 4-h4x0r
          $WS5 = 5-social
          $WS6 = 6-media
          $WS7 = 7-passwd
          $WS8 = 8-ext1
          $WS9 = 9-ext2
          $WS0 = 10-ext3

          $HYPRLAND_CONFIG_PATH = ${config.xdg.configHome}/hypr
          source = $HYPRLAND_CONFIG_PATH/${hostname}.conf
        '';
      };
    };
}
