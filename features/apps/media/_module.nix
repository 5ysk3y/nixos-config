{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

  # Hardware decoding, in the main config and the wallpaper profile
  hwdec = lib.optionalAttrs (config.features.home.media.hwdec != null) {
    inherit (config.features.home.media) hwdec;
    hwdec-codecs = "all";
  };

  # q closes the window and returns focus to the previous workspace
  hyprlandQuit = "run \"/bin/sh\" \"-c\" \"$(which hyprctl) --batch 'dispatch hl.dsp.window.close(); dispatch hl.dsp.focus({ workspace = [[m-1]] })'\"";

  # qutebrowser's profile, for yt-dlp's cookies
  qutebrowserData =
    if isDarwin then "~/Library/Application Support/qutebrowser" else "~/.local/share/qutebrowser";
in
{
  options.features.home.media.hwdec = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "nvdec";
    description = "mpv's hwdec; null leaves mpv's default (software decoding).";
  };

  config = lib.mkMerge [
    {
      home.packages = [
        # VLC is built from source on Linux only; vlc-bin is the upstream
        # macOS app
        (if isDarwin then pkgs.vlc-bin else pkgs.vlc)
      ];

      programs = {
        mpv = {
          enable = true;

          config = {
            geometry = "25%+10+10/1";
            osc = "yes";
            ontop = "yes";

            user-agent = "Mozilla/5.0";
            cache = "yes";
            save-position-on-quit = "yes";
            ytdl-format = "bestvideo+bestaudio";
            stream-buffer-size = "5MiB";
            demuxer-max-bytes = "1G";

            volume = 90;
          }
          // hwdec;
        };

        yt-dlp = {
          enable = true;
          settings = {
            cookies-from-browser = "chromium:'${qutebrowserData}'";
          };
        };
      };
    }

    # The Hyprland desktop: Wayland and PipeWire output, the wallpaper
    # profile, MPRIS, and the Linux-only apps
    (lib.mkIf isLinux {
      # jellyfin-mpv-shim's login to the Jellyfin server
      sops.secrets."services/jellyfin/creds".path =
        "${config.xdg.configHome}/jellyfin-mpv-shim/cred.json";

      xdg.configFile = {
        # Settings, with the player named after this machine in Jellyfin.
        # force replaces a conf.json that isn't Home Manager's, such as one
        # the app wrote itself.
        "jellyfin-mpv-shim/conf.json" = {
          text = builtins.toJSON (
            builtins.fromJSON (builtins.readFile ./files/jellyfin-mpv-shim/conf.json)
            // {
              player_name = hostname;
            }
          );
          force = true;
        };

        # mpv key bindings
        "jellyfin-mpv-shim/input.conf".text = ''
          q run "/bin/sh" "-c" "hyprctl --batch 'dispatch hl.dsp.window.close(); dispatch hl.dsp.focus({ workspace = [[m-1]] })'"
        '';

        "jellyfin-mpv-shim/mpv.conf".text = builtins.readFile ./files/jellyfin-mpv-shim/mpv.conf;
      };

      home.packages = with pkgs; [
        cider-2
        jellyfin-desktop
        jellyfin-mpv-shim
        mpvpaper
        pavucontrol
        playerctl
      ];

      programs = {
        imv.enable = true;

        mpv = {
          bindings.q = hyprlandQuit;

          config = {
            vo = "gpu-next";
            gpu-context = "wayland";
            gpu-api = "opengl";

            ao = "pipewire";

            vd-lavc-dr = "no";
            target-colorspace-hint-mode = "source";
          };

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
      };
    })
  ];
}
