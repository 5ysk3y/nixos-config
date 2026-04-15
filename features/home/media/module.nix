{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
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
        q = "run \"/bin/sh\" \"-c\" \"$(which hyprctl) --batch 'dispatch killactive; dispatch workspace m-1'\"";
      };

      config = {
        geometry = "25%+10+10/1";
        osc = "yes";
        ontop = "yes";

        vo = "gpu-next";
        gpu-context = "wayland";
        gpu-api = "opengl";

        hwdec = "nvdec";
        hwdec-codecs = "all";

        user-agent = "Mozilla/5.0";
        cache = "yes";
        save-position-on-quit = "yes";
        ytdl-format = "bestvideo+bestaudio";
        stream-buffer-size = "5MiB";
        demuxer-max-bytes = "1G";

        ao = "pipewire";
        volume = 90;

        vd-lavc-dr = "no";
      };

      profiles.wallpaper = {
        vo = "gpu";
        gpu-context = "wayland";
        gpu-api = "opengl";
        hwdec = "nvdec";
        hwdec-codecs = "all";

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
      };

      scripts = with pkgs; [
        mpvScripts.mpris
      ];
    };

    yt-dlp.settings = {
      cookies-from-browser = "chromium:'~/.local/share/qutebrowser'";
    };
  };
}
