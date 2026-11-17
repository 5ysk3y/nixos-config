{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Turn the displays back on only once Hyprland has the seat again. After
  # hibernate, logind hands the DRM device back to Hyprland a moment after
  # PrepareForSleep(false). A DPMS commit (or a wtype keypress, which
  # key_press_enables_dpms turns into one) made before then fails with
  # "drm: Session inactive". aquamarine's restore after the seat returns then
  # fails with EINVAL on the outputs DPMS had disabled, and the screens stay
  # black until Hyprland restarts.
  #
  # alwaysSettle: after sleep, logind marks the session active before libseat
  # has processed the ResumeDevice signal, so the session can already look
  # active while aquamarine is still taking the device back. Without it (a
  # plain idle wake), the settle delay only applies if the session wasn't
  # active to begin with.
  waitForSeat =
    { alwaysSettle }:
    ''
      sid=$(${pkgs.systemd}/bin/loginctl show-user "$(id -un)" -p Display --value)
      settle=${if alwaysSettle then "1" else "0"}
      for _ in $(seq 1 60); do
        [ "$(${pkgs.systemd}/bin/loginctl show-session "$sid" -p Active --value)" = yes ] && break
        settle=1
        sleep 0.5
      done
      # Leave aquamarine time to take the device back
      if [ "$settle" = 1 ]; then
        sleep 2
      fi
    '';
  dpmsOn = ''
    hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
    ${pkgs.wtype}/bin/wtype -k escape
  '';

  # After a hibernate that hypridle itself started (the 900s listener), both
  # after_sleep_cmd and the 600s listener's on-resume fire. They share this
  # lock so the listener's DPMS enable can't land in the middle of the
  # resume script's reload: the resume script waits for the lock, and the
  # listener skips its run while the resume script holds it, since that
  # script turns the displays on itself.
  lock = ''
    exec 9>"''${XDG_RUNTIME_DIR:-/tmp}/hypr-resume.lock"
  '';
  flock = "${pkgs.util-linux}/bin/flock";

  dpmsOnWhenActive = pkgs.writeShellScript "hypr-dpms-on-when-active" (
    lock
    + ''
      ${flock} -n 9 || exit 0
    ''
    + waitForSeat { alwaysSettle = false; }
    + dpmsOn
  );

  # After sleep only. When the outputs were still on at suspend, the NVIDIA
  # driver can reject aquamarine's restore with EINVAL as well
  # (hyprwm/aquamarine#387, #433), and nothing retries it. DPMS enable is then
  # a no-op because Hyprland thinks the outputs are on. A reload makes Hyprland
  # re-apply every monitor rule, which modesets the outputs from scratch
  # (hyprwm/Hyprland discussion #17002). It does not re-run hyprland.start.
  resumeAfterSleep = pkgs.writeShellScript "hypr-resume-after-sleep" (
    lock
    + ''
      ${flock} 9
    ''
    + waitForSeat { alwaysSettle = true; }
    + ''
      hyprctl reload
      sleep 1
    ''
    + dpmsOn
  );
in
{
  options.features.home.hyprland.resumeCommands = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "openrgb -c 0000FF -m Direct" ];
    description = "Commands run after waking from sleep, before the displays are turned back on.";
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
              config.features.home.hyprland.resumeCommands ++ [ "${resumeAfterSleep}" ]
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
              on-resume = "${dpmsOnWhenActive}";
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
