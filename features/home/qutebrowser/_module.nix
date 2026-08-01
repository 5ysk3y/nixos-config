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

        c.statusbar.padding = {"bottom": 6, "left": 8, "right": 8, "top": 6}
        c.tabs.padding = {"bottom": 6, "left": 8, "right": 8, "top": 6}

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

      settings = {

        downloads.remove_finished = 300000;
        fonts.default_size = lib.mkForce "8pt";
        qt.chromium.process_model = "process-per-site";
        scrolling.smooth = true;
        statusbar.show = "in-mode";
        url.default_page = "https://search.brave.com/";

        auto_save = {
          session = true;
        };

        colors = {
          webpage = {
            bg = "light grey";
            darkmode = {
              algorithm = "lightness-cielab";
              enabled = true;
              policy.images = "never";
              threshold.background = 150;
            };
          };
        };

        content = {
          autoplay = false;
          cookies.accept = "no-3rdparty";
          fullscreen.window = false;
          geolocation = false;
          headers.user_agent = "Mozilla/5.0 ({os_info}) AppleWebKit/{webkit_version} (KHTML, like Gecko) {qt_key}/{qt_version} {upstream_browser_key}/{upstream_browser_version} Safari/{webkit_version}";
          xss_auditing = true;
        };

        tabs = {
          background = true;
          new_position.related = "last";
          pinned.frozen = false;
          title.format = "{index}: {current_title}";
        };

        window = {
          title_format = "qutebrowser";
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
