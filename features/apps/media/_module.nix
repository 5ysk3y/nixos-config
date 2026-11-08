{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Hardware decoding, in the main config and the wallpaper profile
  hwdec = lib.optionalAttrs (config.features.home.media.hwdec != null) {
    inherit (config.features.home.media) hwdec;
    hwdec-codecs = "all";
  };
in
{
  options.features.home.media.hwdec = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "nvdec";
    description = "mpv's hwdec; null leaves mpv's default (software decoding).";
  };

  config = {
    home.packages = with pkgs; [
      cider-2
      jellyfin-desktop
      jellyfin-mpv-shim
      mpvpaper
      pavucontrol
      playerctl
      vlc
    ];

    programs = {
      imv.enable = true;

      mpv = {
        enable = true;

        bindings = {
          q = "run \"/bin/sh\" \"-c\" \"$(which hyprctl) --batch 'dispatch hl.dsp.window.close(); dispatch hl.dsp.focus({ workspace = [[m-1]] })'\"";
        };

        config = {
          geometry = "25%+10+10/1";
          osc = "yes";
          ontop = "yes";

          vo = "gpu-next";
          gpu-context = "wayland";
          gpu-api = "opengl";

          user-agent = "Mozilla/5.0";
          cache = "yes";
          save-position-on-quit = "yes";
          ytdl-format = "bestvideo+bestaudio";
          stream-buffer-size = "5MiB";
          demuxer-max-bytes = "1G";

          ao = "pipewire";
          volume = 90;

          vd-lavc-dr = "no";
          target-colorspace-hint-mode = "source";
        }
        // hwdec;

        profiles.wallpaper = {
          vo = "gpu";
          gpu-context = "wayland";
          gpu-api = "opengl";

          osc = "no";
          input-default-bindings = "no";
          input-vo-keyboard = "no";

          deband = "no";
          interpolation = "no";
          deinterlace = "no";

          correct-downscaling = "no";
          scale = "bilinear";
          cscale = "bilinear";
          dscale = "bilinear";
          tscale = "oversample";

          save-position-on-quit = "no";
          watch-later-options = "no";

          cache = "no";
          framedrop = "vo";

          loop-file = "inf";
          vf = "fps=30";
        }
        // hwdec;

        scripts = with pkgs; [
          mpvScripts.mpris
        ];
      };

      yt-dlp.settings = {
        cookies-from-browser = "chromium:'~/.local/share/qutebrowser'";
      };
    };
  };
}
