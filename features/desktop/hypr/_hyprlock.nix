{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = config.features.home.hyprlock;

  # Unlocks with a YubiKey touch alongside the password field, the way
  # hyprlock's fingerprint support works. While hyprlock runs, a loop asks
  # the hyprlock-u2f PAM service (pam_u2f only, see ./_nixos.nix) for a
  # touch, starts a new request each time one times out or fails, and sends
  # hyprlock SIGUSR1 (its unlock signal) once one succeeds. After resume, the
  # next request finds the key again as soon as it's back on USB.
  wrapper = pkgs.writeShellScript "hyprlock" ''
    ${pkgs.hyprlock}/bin/hyprlock "$@" &
    lock=$!
    user=$(${pkgs.coreutils}/bin/id -un)
    (
      while kill -0 "$lock" 2>/dev/null; do
        if ${pkgs.pamtester}/bin/pamtester hyprlock-u2f "$user" authenticate >/dev/null 2>&1; then
          kill -USR1 "$lock"
          exit
        fi
        sleep 1
      done
    ) &
    watcher=$!
    wait "$lock"
    status=$?
    # After a password unlock, the loop is still waiting for a touch
    ${pkgs.procps}/bin/pkill -P "$watcher"
    kill "$watcher" 2>/dev/null
    exit "$status"
  '';

  hyprlock = pkgs.symlinkJoin {
    name = "hyprlock-u2f-${pkgs.hyprlock.version}";
    paths = [ pkgs.hyprlock ];
    inherit (pkgs.hyprlock) meta;
    postBuild = ''
      rm $out/bin/hyprlock
      ln -s ${wrapper} $out/bin/hyprlock
    '';
  };

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

  config = {
    programs.hyprlock = {
      enable = true;
      package = if osConfig.security.pam.u2f.enable then hyprlock else pkgs.hyprlock;

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
