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
      rbw unlocked > /dev/null 2>&1
      RC="$?"

      if [[ "$RC" -eq 1 ]]; then
        kitty -T "rbw password prompt" \
          rbw unlock > /dev/null 2>&1 \
          && hyprctl dispatch focuswindow qutebrowser \
          && rofi-rbw
      else
        rofi-rbw
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

      greasemonkey = [
        (pkgs.writeText "chatgpt-autocleaner-v5.user.js" ''
          // ==UserScript==
          // @name         ChatGPT AutoCleaner v5
          // @version      1.5
          // @description  Bugfix & speed-up for ChatGPT: cleans the conversation chat window by trimming old messages from the Browser DOM. Keeps only the latest N turns visible, preventing lag and excessive DOM size on long sessions. Includes manual “Clean now” button and auto-clean toggle.
          // @author       Aleksey Maximov <amaxcz@gmail.com>
          // @match        https://chat.openai.com/*
          // @match        https://chatgpt.com/*
          // @grant        none
          // @namespace    81e29c9d-b6e3-4210-b862-c93cb160f09a
          // @license      MIT
          // ==/UserScript==
           
           
           
          /*
          WHY THIS FIX EXISTS (read this once):
           
          Problem:
          - The ChatGPT web app keeps adding conversation turns to the DOM indefinitely.
          - On long sessions the DOM grows huge → reflows/repaints become expensive → UI lags.
          - React also keeps its own internal arrays with messages, drafts, telemetry and other
            data that never gets freed properly. This is a major source of memory bloat, but
            the safe way to clean it without breaking features is still unclear.
           
          What this script changes:
          - On a timer, it trims old DOM turns (visual cleanup only).
          - Adds a **Clean now** button to trigger immediate trim.
          - Auto-clean can be enabled/disabled, and interval/keep count adjusted.
          - Skips auto-clean when the tab is hidden.
           
          Result:
          - Only the latest N messages remain in the DOM.
          - Old nodes are removed → browser memory/paint workload drops.
          - React’s hidden memory leaks still remain, but DOM cleanup alone already makes
            long sessions much smoother. Further fixes are TBD.
          */
           
           
          (function () {
            'use strict';
           
            // ---------- UI ----------
            function injectUI() {
              if (document.getElementById("chatgpt-cleaner-panel")) return;
           
              const defaults = { leaveOnly: 5, intervalSec: 10, enabled: false };
              const stored = {
                leaveOnly: parseInt(localStorage.getItem("chatgpt-leaveOnly")) || defaults.leaveOnly,
                intervalSec: parseInt(localStorage.getItem("chatgpt-intervalSec")) || defaults.intervalSec,
                enabled: localStorage.getItem("chatgpt-enabled") !== "false"
              };
           
              const container = document.createElement("div");
              container.id = "chatgpt-cleaner-wrapper";
              Object.assign(container.style, {
                position: "fixed", bottom: "8px", right: "8px", zIndex: 9999, fontFamily: "sans-serif"
              });
           
              const toggleButton = document.createElement("button");
              toggleButton.textContent = "⚙";
              Object.assign(toggleButton.style, {
                background: stored.enabled ? "#444" : "red", color: "#fff", border: "none",
                borderRadius: "4px", padding: "2px 6px", cursor: "pointer", fontSize: "14px"
              });
              toggleButton.title = "Toggle cleaner panel";
           
              const panel = document.createElement("div");
              panel.id = "chatgpt-cleaner-panel";
              Object.assign(panel.style, {
                display: "none", marginTop: "4px", background: "#222", color: "#fff",
                padding: "10px 12px 10px 10px", borderRadius: "6px", fontSize: "12px",
                boxShadow: "0 0 6px rgba(0,0,0,0.5)", border: "1px solid #555", position: "relative", opacity: "0.95"
              });
           
              panel.innerHTML = `
                <div id="chatgpt-close" style="position:absolute;top:0px;right:2px;font-size:16px;font-weight:bold;color:#ccc;cursor:pointer;">✖</div>
                <label>
                  Keep <input id="chatgpt-keep-count" type="number" value="''${stored.leaveOnly}" min="1"
                  style="width:52px;min-width:52px;padding:2px 6px 2px 4px;font-size:12px;background:#111;color:#fff;border:1px solid #555;box-sizing:border-box;"> messages
                </label>
                <br>
                <label>
                  Interval <input id="chatgpt-interval" type="number" value="''${stored.intervalSec}" min="2"
                  style="width:52px;min-width:52px;padding:2px 6px 2px 4px;font-size:12px;background:#111;color:#fff;border:1px solid #555;box-sizing:border-box;"> sec
                </label>
                <br>
                <label><input type="checkbox" id="chatgpt-enabled" ''${stored.enabled ? "checked" : ""}> Auto-clean enabled</label>
                <br>
                <button id="chatgpt-clean-now" style="
                  margin-top:6px;background:#008000;color:#fff;border:none;border-radius:4px;
                  padding:2px 8px;cursor:pointer;font-size:12px;">Clean now</button>
              `;
           
              toggleButton.onclick = () => { panel.style.display = "block"; toggleButton.style.display = "none"; };
              container.appendChild(toggleButton);
              container.appendChild(panel);
              document.body.appendChild(container);
           
              const countInput = panel.querySelector("#chatgpt-keep-count");
              const intervalInput = panel.querySelector("#chatgpt-interval");
              const enabledCheckbox = panel.querySelector("#chatgpt-enabled");
              const cleanNowBtn = panel.querySelector("#chatgpt-clean-now");
              const closeBtn = panel.querySelector("#chatgpt-close");
           
              let leaveOnly = stored.leaveOnly;
              let intervalMs = Math.max(2000, stored.intervalSec * 1000);
              let enabled = stored.enabled;
              let intervalId = null;
           
           
              function scheduleClean(force = false) {
                if (!force) {
                  if (!enabled) return;
                  if (document.hidden) return;
                }
                cleanOldMessages(force);
                                     }
           
           
              // ---------- main cleaner (no gating here; gating is in scheduleClean) ----------
              function cleanOldMessages(manual = false) {
                try {
                  if (manual) console.info("[AutoCleaner] Manual clean");
                  // 1) Trim DOM (visual only)
                  const all = document.querySelectorAll('[data-testid^="conversation-turn-"]');
                  if (all.length) {
                    const lastAttr = all[all.length - 1].getAttribute("data-testid");
                    const last = parseInt(lastAttr?.split("-")[2]);
                    if (!isNaN(last)) {
                      all.forEach(item => {
                        const idx = parseInt(item.getAttribute("data-testid")?.split("-")[2]);
                        if (!isNaN(idx) && idx < last - leaveOnly) item.remove();
                                  });
                    }
                  }
                  // console.info("[AutoCleaner] Working...");
           
                                        } catch (e) {
                  console.error("[AutoCleaner] clean error:", e);
                                        }
                                                      }
           
              function startCleaner() {
                if (intervalId) clearInterval(intervalId);
                intervalId = setInterval(() => scheduleClean(false), intervalMs);
                console.info(`[AutoCleaner] Started: interval=''${intervalMs}ms, keep=''${leaveOnly}`);
              }
           
              // ---------- handlers ----------
              enabledCheckbox.onchange = () => {
                enabled = enabledCheckbox.checked;
                localStorage.setItem("chatgpt-enabled", enabled);
                toggleButton.style.background = enabled ? "#444" : "red";
                console.debug("[AutoCleaner] enabled =", enabled);
                 };
           
              countInput.oninput = () => {
                const val = parseInt(countInput.value);
                if (!isNaN(val) && val > 0) {
                  leaveOnly = val;
                  localStorage.setItem("chatgpt-leaveOnly", val);
                  console.debug("[AutoCleaner] keep set to", leaveOnly);
                }
              };
           
              intervalInput.oninput = () => {
                const val = parseInt(intervalInput.value);
                if (!isNaN(val) && val > 1) {
                  intervalMs = Math.max(2000, val * 1000);
                  localStorage.setItem("chatgpt-intervalSec", val);
                  startCleaner();
                }
              };
           
              cleanNowBtn.onclick = () => {
                console.info("[AutoCleaner] CLEAN NOW clicked");
                scheduleClean(true);
                panel.style.display = "none";
                toggleButton.style.display = "inline-block";
              };
           
              closeBtn.onclick = () => {
                panel.style.display = "none";
                toggleButton.style.display = "inline-block";
              };
           
              startCleaner();
                                                          }
           
            if (document.readyState === "complete" || document.readyState === "interactive") {
              injectUI();
                } else {
              window.addEventListener("DOMContentLoaded", injectUI);
                }
           
            const observer = new MutationObserver(() => {
              if (!document.getElementById("chatgpt-cleaner-wrapper")) injectUI();
                       });
            observer.observe(document.body, { childList: true, subtree: true });
                                                        })();
        '')
      ];
    };

    rofi = lib.mkIf isLinux {
      enable = true;
      package = pkgs.rofi;
    };
  };
}
