{ config, lib, pkgs, inputs, vars, ... }: {

  options = with lib; {
    applications = {
      qutebrowser = mkEnableOption "Enable qutebrowser with custom configs";
    };
  };

  config = with lib; mkIf config.applications.qutebrowser {
    programs = {
      qutebrowser = {
        enable = true;
        extraConfig = ''
          import dracula.draw

          # Load existing settings made via :set
          config.load_autoconfig(False)

          dracula.draw.blood(c, {
              'spacing': {
                  'vertical': 6,
                  'horizontal': 8
              }
          })

          c.auto_save.session = True

          c.fonts.default_family = ["Hack"]
          c.fonts.default_size = '8pt'

          c.colors.downloads.start.bg = "#282a36"
          c.colors.downloads.start.fg = "#f8f8f2"
          c.colors.webpage.bg = "light grey"
          c.colors.webpage.darkmode.algorithm = "lightness-cielab"
          c.colors.webpage.darkmode.enabled = True
          c.colors.webpage.darkmode.policy.images = "never"
          c.colors.webpage.darkmode.threshold.background = 150
          c.colors.webpage.preferred_color_scheme = "dark"

          c.content.autoplay = False
          c.content.cookies.accept = "no-3rdparty"
          c.content.fullscreen.window = False
          c.content.geolocation = False
          c.content.headers.user_agent = "Mozilla/5.0 ({os_info}) AppleWebKit/{webkit_version} (KHTML, like Gecko) {qt_key}/{qt_version} {upstream_browser_key}/{upstream_browser_version} Safari/{webkit_version}"
          c.content.xss_auditing = True

          c.downloads.remove_finished = 300000
          c.qt.chromium.process_model = "process-per-site-instance"
          c.scrolling.smooth = True
          c.statusbar.show = "in-mode"

          c.tabs.background = True
          c.tabs.new_position.related = "last"
          c.tabs.pinned.frozen = False
          c.tabs.title.format = "{index}: {current_title}"

          c.window.title_format = "qutebrowser"

          c.qt.args = ["enable-gpu-rasterization", "ignore-gpu-blocklist"]
              '';

        keyBindings = {
          normal = {
            ",M" = "hint links spawn mpv {hint-url}";
            ",m" = "spawn mpv {url}";
            ";M" = "hint --rapid links spawn mpv {hint-url}";
            "<Ctrl+Shift+i>:" = "devtools";
            "<Ctrl+l>" = "mode-enter insert ;; spawn -u /etc/profiles/per-user/${vars.username}/bin/qute-rbw";
            "xb" = "config-cycle statusbar.hide";
          };

          insert = {
            "<Ctrl+l>" = "spawn -u /etc/profiles/per-user/${vars.username}/bin/qute-rbw";
          };

          passthrough = {
              "<Ctrl+x>" = "mode-leave";
          };
        }; # End Keybindings

        quickmarks = {
          yt = "https://youtube.com";
          htb = "https://app.hackthebox.eu/";
          thm = "https://tryhackme.com";
          nixpkgs = "https://search.nixos.org/packages";
          nix-tracker = "https://nixpk.gs/pr-tracker.html";
          github = "https://github.com/";
          amazon = "https://www.amazon.co.uk/";
        }; # End quickmarks

        searchEngines = {
          DEFAULT = "https://search.brave.com/search?q={}";
          aw = "https://wiki.archlinux.org/?search={}";
          google = "https://google.com/search?q={}";
          gtfo = "https://gtfobins.github.io/#{}";
        };

      }; # End qutebrowser

    }; # End programs

  }; # End config
}
