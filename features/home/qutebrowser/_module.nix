{
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  quteRbw = pkgs.writeShellApplication {
    name = "qute-rbw";

    runtimeInputs = [
      pkgs.rbw
      pkgs.kitty
      pkgs.rofi-rbw-wayland
      pkgs.pinentry-curses
      pkgs.hyprland
    ];

    text = ''
      if rbw unlocked > /dev/null 2>&1; then
        rofi-rbw
      else
        kitty -T "rbw password prompt" rbw unlock \
        && hyprctl dispatch focuswindow qutebrowser \
        && rofi-rbw
      fi
    '';
  };
in
{
  home.packages = lib.mkIf isLinux [ quteRbw ];

  programs = {
    qutebrowser = {
      enable = true;

      extraConfig = ''
        # Load existing settings made via :set
        config.load_autoconfig(False)

        c.auto_save.session = True

        c.fonts.default_family = ["Hack"]
        c.fonts.default_size = '8pt'

        c.colors.webpage.bg = "light grey"
        c.colors.webpage.darkmode.algorithm = "lightness-cielab"
        c.colors.webpage.darkmode.enabled = True
        c.colors.webpage.darkmode.policy.images = "never"
        c.colors.webpage.darkmode.threshold.background = 150

        c.content.autoplay = False
        c.content.cookies.accept = "no-3rdparty"
        c.content.fullscreen.window = False
        c.content.geolocation = False
        c.content.headers.user_agent = "Mozilla/5.0 ({os_info}) AppleWebKit/{webkit_version} (KHTML, like Gecko) {qt_key}/{qt_version} {upstream_browser_key}/{upstream_browser_version} Safari/{webkit_version}"
        c.content.xss_auditing = True

        c.downloads.remove_finished = 300000
        c.qt.chromium.process_model = "process-per-site"
        c.scrolling.smooth = True
        c.statusbar.show = "in-mode"
        c.statusbar.padding = {"bottom": 6, "left": 8, "right": 8, "top": 6}

        c.tabs.background = True
        c.tabs.new_position.related = "last"
        c.tabs.pinned.frozen = False
        c.tabs.title.format = "{index}: {current_title}"
        c.tabs.padding = {"bottom": 6, "left": 8, "right": 8, "top": 6}

        c.window.title_format = "qutebrowser"

        c.qt.args = (c.qt.args or []) + [
          "--site-per-process",
          "--disable-features=ProcessSharingWithDefaultSiteInstances",
          "--disable-background-timer-throttling",
          "--disable-backgrounding-occluded-windows"
        ]
        c.qt.workarounds.disable_accessibility = "always"
        c.qt.force_software_rendering = "chromium"
      '';

      keyBindings = {
        normal = lib.mkMerge [
          {
            ",M" = "hint links spawn mpv {hint-url}";
            ",m" = "spawn mpv {url}";
            ";M" = "hint --rapid links spawn mpv {hint-url}";
            "<Ctrl+Shift+i>:" = "devtools";
            "xb" = "config-cycle statusbar.show always never";
            "er" = "spawn -u readability";
          }
          (lib.mkIf isLinux {
            "<Ctrl+l>" = "mode-enter insert ;; spawn -u ${quteRbw}/bin/qute-rbw";
          })
        ];

        insert = lib.mkMerge [
          { }
          (lib.mkIf isLinux {
            "<Ctrl+l>" = "mode-enter insert ;; spawn -u ${quteRbw}/bin/qute-rbw";
          })
        ];

        passthrough = {
          "<Ctrl+x>" = "mode-leave";
        };
      };

      quickmarks = {
        yt = "https://youtube.com";
        htb = "https://app.hackthebox.eu/";
        thm = "https://tryhackme.com";
        nixpkgs = "https://search.nixos.org/packages";
        nix-tracker = "https://nixpk.gs/pr-tracker.html";
        github = "https://github.com/";
        amazon = "https://www.amazon.co.uk/";
      };

      searchEngines = {
        DEFAULT = "https://search.brave.com/search?q={}";
        aw = "https://wiki.archlinux.org/?search={}";
        google = "https://google.com/search?q={}";
        gtfo = "https://gtfobins.github.io/#{}";
      };

    };

    rofi = lib.mkIf isLinux {
      enable = true;
      package = pkgs.rofi;
    };
  };
}
