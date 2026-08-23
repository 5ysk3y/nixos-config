{
  config,
  lib,
  pkgs,
  ...
}:
{
  config =
    with lib;
    mkIf pkgs.stdenv.hostPlatform.isLinux {
      services = {
        hypridle = {
          enable = true;
          settings = {
            general = {
              lock_cmd = "pidof hyprlock || hyprlock";
              after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'; wtype -k escape; openrgb -p ${config.xdg.configHome}/OpenRGB/MainBlue.orp;";
              on_unlock_cmd = "wtype -k escape";
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
                on-timeout = "sleep 1 && hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'";
                on-resume = "sleep 1 && hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
              }
              {
                timeout = 900;
                on-timeout = "systemctl hibernate";
              }
            ];
          };
        };
      };
    };
}
