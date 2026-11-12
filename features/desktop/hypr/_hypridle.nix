{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.features.home.hyprland.resumeCommands = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "openrgb -c 0000FF -m Direct" ];
    description = "Commands run after waking from sleep, before the displays are cycled.";
  };

  config = {
    home.packages = with pkgs; [ wtype ];
    services = {
      hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock";
            after_sleep_cmd = lib.concatStringsSep "; " (
              [
                "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'"
                "wtype -k escape"
              ]
              ++ config.features.home.hyprland.resumeCommands
            );
            on_unlock_cmd = "wtype -k escape";
          };

          listener = [
            {
              timeout = 300;
              on-timeout = "dimland -a 0.5";
              on-resume = "dimland stop";
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
