{
  config,
  lib,
  pkgs,
  inputs,
  vars,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  quteRbw = pkgs.writeShellScriptBin "qute-rbw" ''
    ${pkgs.rbw}/bin/rbw unlocked > /dev/null 2>&1
    RC="$?"

    if [[ "$RC" -eq 1 ]]; then
      ${pkgs.kitty}/bin/kitty -T "rbw password prompt" \
        ${pkgs.rbw}/bin/rbw unlock > /dev/null 2>&1 \
        && ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow qutebrowser \
        && ${pkgs.rofi-rbw-wayland}/bin/rofi-rbw
    else
      ${pkgs.rofi-rbw-wayland}/bin/rofi-rbw
    fi
  '';
in
{
  options = with lib; {
    applications = {
      qutebrowser = mkEnableOption "Enable qutebrowser with custom configs";
    };
  };

  config =
    with lib;
    mkIf config.applications.qutebrowser {
      home.packages = lib.mkIf isLinux [ quteRbw ];
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
            c.qt.chromium.process_model = "process-per-site"
            c.scrolling.smooth = True
            c.statusbar.show = "in-mode"

            c.tabs.background = True
            c.tabs.new_position.related = "last"
            c.tabs.pinned.frozen = False
            c.tabs.title.format = "{index}: {current_title}"

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
          }; # End keybinds

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

          greasemonkey = [
            (pkgs.writeText "chatgpt-slimmer.user.js" ''
              // ==UserScript==
              // @name         ChatGPT DOM Slimmer (Memory Friendly)
              // @namespace    qutebrowser
              // @version      1.2
              // @description  Collapses older messages into placeholders while releasing DOM memory, keeps last 50 visible
              // @match        https://chat.openai.com/*
              // @match        https://chatgpt.com/*
              // @run-at       document-idle
              // @grant        none
              // ==/UserScript==

              (function () {
                "use strict";

                var MAX_VISIBLE = 50;
                var PLACEHOLDER_CLASS = "gm-msg-placeholder";
                var COLLAPSED_ATTR = "data-gm-collapsed";
                var STORE_ATTR = "data-gm-html";

                function getMessages() {
                  // Selector is intentionally conservative, ChatGPT markup shifts.
                  // If this breaks, first thing to adjust is this selector.
                  return Array.from(document.querySelectorAll("main article"));
                }

                function makePlaceholder(index, html) {
                  var ph = document.createElement("div");
                  ph.className = PLACEHOLDER_CLASS;
                  ph.setAttribute(COLLAPSED_ATTR, "true");
                  ph.setAttribute(STORE_ATTR, html);

                  ph.textContent = "🔽 Collapsed message " + (index + 1) + ". Click to expand";

                  ph.style.cssText = [
                    "padding: 10px",
                    "margin: 5px 0",
                    "background: #2d2d2d",
                    "border: 1px dashed #666",
                    "border-radius: 6px",
                    "color: #aaa",
                    "font-size: 14px",
                    "cursor: pointer",
                    "user-select: none"
                  ].join("; ");

                  ph.addEventListener("click", function () {
                    var stored = ph.getAttribute(STORE_ATTR) || "";
                    var tpl = document.createElement("template");
                    tpl.innerHTML = stored;

                    // Replace placeholder with the reconstructed message nodes.
                    // If stored HTML had a single root element (it should), we insert that.
                    var node = tpl.content.firstElementChild;
                    if (node) {
                      ph.replaceWith(node);
                      // Mark it as pinned so it won't immediately get collapsed again.
                      node.setAttribute("data-gm-pinned", "true");
                    }
                  });

                  return ph;
                }

                function collapseOldMessages() {
                  var messages = getMessages();
                  if (messages.length <= MAX_VISIBLE) return;

                  var toCollapse = messages.slice(0, messages.length - MAX_VISIBLE);

                  for (var i = 0; i < toCollapse.length; i++) {
                    var msg = toCollapse[i];

                    // If user expanded it, don't re-collapse.
                    if (msg.getAttribute("data-gm-pinned") === "true") continue;

                    // Avoid collapsing twice if already replaced.
                    // Also avoid collapsing placeholders if selector ever changes.
                    if (msg.classList && msg.classList.contains(PLACEHOLDER_CLASS)) continue;

                    // Store HTML and release the DOM node.
                    var html = msg.outerHTML;

                    var ph = makePlaceholder(i, html);
                    msg.replaceWith(ph);
                  }
                }

                // Debounce work, ChatGPT causes a huge number of mutations.
                var timer = null;
                function scheduleCollapse() {
                  if (timer) window.clearTimeout(timer);
                  timer = window.setTimeout(function () {
                    // Use idle time if possible.
                    if (window.requestIdleCallback) {
                      window.requestIdleCallback(collapseOldMessages, { timeout: 1500 });
                    } else {
                      collapseOldMessages();
                    }
                  }, 600);
                }

                var observer = new MutationObserver(scheduleCollapse);
                observer.observe(document.body, { childList: true, subtree: true });

                // Also run after scroll settles, long threads tend to stutter while scrolling.
                var scrollTimer = null;
                window.addEventListener("scroll", function () {
                  if (scrollTimer) window.clearTimeout(scrollTimer);
                  scrollTimer = window.setTimeout(scheduleCollapse, 250);
                }, { passive: true });

                window.setTimeout(scheduleCollapse, 1500);
              })();
            '')
          ];

        }; # End qutebrowser

        rofi = lib.mkIf isLinux {
          enable = true;
          package = pkgs.rofi;
        }; # End rofi
      }; # End programs
    }; # End config
}
