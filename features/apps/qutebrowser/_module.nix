{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Fills and copies Bitwarden logins. Comes with the rbw feature.
  quteRbw = import ./_qute-rbw {
    inherit lib pkgs;
    rbw = config.programs.rbw.package;
  };
  rbw = command: "spawn -u ${lib.getExe quteRbw} ${command}";
  withRbw = lib.mkIf config.programs.rbw.enable;
in
{
  programs = {
    qutebrowser = {
      enable = true;

      extraConfig = ''
        # Ignore settings made via :set (autoconfig.yml); config lives here
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
            "<Ctrl+Shift+i>" = "devtools";
            "xb" = "config-cycle statusbar.show always never";
            "er" = "spawn -u readability";
          }
          (withRbw {
            # Fill the login form: username, password, and the TOTP code
            # onto the clipboard for the next step
            "<Ctrl+l>" = rbw "login";
            # Pick from every match, even when one is an obvious fit
            ",pl" = rbw "--pick login";
            # Fill one field: the focused one, or the likeliest on the page
            ",pu" = rbw "username";
            ",pp" = rbw "password";
            ",pt" = rbw "totp";
            # Copy one field, cleared again after a while
            ",yu" = rbw "--copy username";
            ",yp" = rbw "--copy password";
            ",yt" = rbw "--copy totp";
          })
        ];

        insert = withRbw {
          "<Ctrl+l>" = rbw "login";
          "<Ctrl+t>" = rbw "totp";
        };

        passthrough = {
          "<Ctrl+x>" = "mode-leave";
        };
      };

      settings = {

        downloads.remove_finished = 300000;
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
          tls = {
            certificate_errors = "block";
          };
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
  };
}
