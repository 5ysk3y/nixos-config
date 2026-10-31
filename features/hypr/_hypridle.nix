{
  config,
  lib,
  pkgs,
  ...
}:
let
  resumeDpms = pkgs.writeShellScript "hypr-resume-dpms" ''
    sid=$(${pkgs.systemd}/bin/loginctl show-user "$(id -un)" -p Display --value)
    for i in $(seq 1 60); do
      [ "$(${pkgs.systemd}/bin/loginctl show-session "$sid" -p Active --value)" = yes ] && break
      sleep 0.5
    done
    echo "resume-dpms: session $sid active after ''${i} polls"
    sleep 3
    hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'
    sleep 1
    hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
  '';
in
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
              after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'; wtype -k escape; openrgb -p ${config.xdg.configHome}/OpenRGB/MainBlue.orp; ${resumeDpms}";
              on_unlock_cmd = "wtype -k escape";
            };

            listener = [
              {
                timeout = 300;
                on-timeout = "dim -p -d 0";
                on-resume = "pkill dim";
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
