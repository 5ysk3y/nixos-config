{
  config,
  lib,
  pkgs,
  inputs,
  vars,
  ...
}:

{
  home = with pkgs; {
    username = "${vars.username}";
    homeDirectory = "/home/${vars.username}";

    pointerCursor = {
      gtk.enable = true;
      package = bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 22;
    };

    sessionVariables = {
      NIXOS_OZONE_WL = 1;
      QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";
    };

    packages = with pkgs; [
      bat
      bitwarden-desktop
      bottles
      dracula-theme
      fontconfig
      glib
      grimblast
      heroic
      hyprpolkitagent
      (inputs.nixos-xivlauncher-rb.packages.${stdenv.hostPlatform.system}.default.override {
        useGameMode = true;
      })
      (import ../modules/applications/dim-screen { inherit pkgs; })
      jellyfin-mpv-shim
      jq
      keyutils
      krita
      libnotify
      mpvpaper
      nixfmt
      nixd
      neofetch
      obs-cmd
      pavucontrol
      pinentry-curses
      playerctl
      protonup-qt
      pwvucontrol
      restic
      rivalcfg
      rofi-rbw-wayland
      signal-desktop-bin
      sops
      spice-gtk
      vlc
      vulkan-tools
      webcord
      wl-clipboard
      wtype
    ];
  };

  ## CUSTOM MODULES

  confSymlinks = {
    enable = true;
    configs = {
      jellyfinShim = true;
      openrgb = true;
      streamdeckui = true;
      webcord = true;
    };
  };

  scripts = {
    enable = true;
  };

  applications = {
    hypr.enable = true;
    doomemacs = true;
  };

  ## END CUSTOM MODULES
  ## BEGIN PROGRAMS

  programs = with pkgs; {
    zsh = {
      dotDir = "${config.xdg.configHome}/zsh";
      loginExtra = ''
        start-hyprland && exit
      '';
      shellAliases = {
        ls = "ls --color";
        ll = "ls -lash";
        build-nix = "nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'";
        cpu_usage = "ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%cpu | head";
        mem_usage = "ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%mem | head";
        shred = "shred -zfu";
        nixos-rebuild = "systemd-inhibit --no-pager --no-legend --mode=block --who='${vars.username}' --why='NixOS Upgrades' sudo nixos-rebuild --flake \${NIXOS_CONFIG:-$HOME/nixos-config}#gibson $@ --option eval-cache false --show-trace";
        spicy = "spicy --spice-ca-file=/etc/pki/libvirt-spice/ca-cert.pem --uri 'spice://127.0.0.1' -p 5900 -s 5901 --title 'th3h4x0r' -f > /dev/null 2>&1 &|";
        pass = "pass -c main";
      };
      history = {
        path = "${config.xdg.dataHome}/zsh/zsh_history";
      };
      initContent = ''
        vim() {
          emacsclient -c --tty "$@"
        }

        bindkey -M viins '\e.' insert-last-word
      '';
    };

    git = {
      settings = {
        user.signingKey = "7D73BA8CF10F7F67";
      };
    };

    imv = {
      enable = true;
    };

    password-store = {
      enable = true;
      settings = {
        PASSWORD_STORE_DIR = "${config.xdg.dataHome}/pass";
      };
    };

    rbw = {
      enable = true;
    };

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
        hwdec-codecs = "all"; # fixed key name

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

      profiles = {
        wallpaper = {
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
      };

      scripts = [
        mpvScripts.mpris
      ];
    };

    mangohud = {
      enable = true;
    };

    yt-dlp = {
      settings = {
        cookies-from-browser = "chromium:'~/.local/share/qutebrowser'";
      };
    };

    obs-studio = {
      enable = true;
      plugins = [
        obs-studio-plugins.obs-vaapi
        obs-studio-plugins.obs-pipewire-audio-capture
        obs-studio-plugins.obs-scale-to-sound
        obs-studio-plugins.obs-vkcapture
        obs-studio-plugins.obs-gstreamer
      ];
    };

    kitty = {
      enable = true;
      themeFile = "Dracula";
      font = {
        name = "Noto Sans Mono";
        size = 10.0;
      };
      shellIntegration = {
        enableZshIntegration = true;
      };
      settings = {
        enabled_layouts = "stack";
        window_padding_width = 9;
        placement_strategy = "top-left";
        confirm_os_window_close = 3;
        background_opacity = "0.7";
      };
    };

    gpg = {
      scdaemonSettings = {
        disable-ccid = true;
      };
    };
  };

  ## END PROGRAMS
  ## START SERVICES

  services = with pkgs; {
    playerctld = {
      enable = true;
    };

    mako = {
      enable = true;
      settings = {
        output = "DP-1";
        background-color = "#282A36";
        text-color = "#FFFFFF";
        padding = "10";
        font = "Tamzen 12";
        layer = "overlay";
        anchor = "top-right";
        margin = "11";
        default-timeout = 20000;
        border-size = 1;
        border-radius = 5;
        width = 400;
        height = 170;
        max-icon-size = 32;

        "urgency=low" = {
          border-color = "#BD93F9";
        };
        "urgency=normal" = {
          border-color = "#BD93F9";
          on-notify = "exec ${pkgs.vlc}/bin/cvlc --play-and-exit ${config.xdg.configHome}/mako/notification.wav";
        };
        "urgency=high" = {
          border-color = "#FF5555";
          on-notify = "exec ${pkgs.vlc}/bin/cvlc --play-and-exit ${config.xdg.configHome}/mako/notification.wav";
        };
        "mode=idle" = {
          default-timeout = 0;
          ignore-timeout = 1;
        };
      };
    };

    gpg-agent = {
      enable = true;
      pinentry = {
        package = pinentry-curses;
      };
    };

    wayland-pipewire-idle-inhibit = {
      enable = true;
      systemdTarget = "graphical-session.target";
      settings = {
        verbosity = "INFO";
        media_minimum_duration = 10;
        idle_inhibitor = "wayland";

        sink_whitelist = [
          { name = "HDMI / External"; }
        ];
      };
    };
  };

  ## END SERVICES ##
  ## XDG SPEC

  xdg = {
    enable = true;
    portal = {
      enable = true;
      config = {
        common = {
          default = [
            "hyprland"
          ];
        };
      };
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk # Added as per https://wiki.hyprland.org/Hypr-Ecosystem/xdg-desktop-portal-hyprland/
      ];
      configPackages = [ pkgs.hyprland ];
    };
  };

  # GTK

  gtk = with pkgs; {
    enable = true;
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = bibata-cursors;
    };
    theme = {
      name = "Dracula";
      package = dracula-theme;
    };
    iconTheme = {
      name = "Bibata-Modern-Classic";
      package = bibata-cursors;
    };
    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
  };

  nix = {
    gc = {
      automatic = true;
      options = "-d";
    };
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  ## SOPSNIX

  sops = {
    age.keyFile = "/var/lib/age/keys.txt";
    defaultSopsFile = "${vars.secretsPath}/secrets/secrets.yaml";
    defaultSopsFormat = "yaml";

    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";

    secrets = {
      ## jellyfin
      "services/jellyfin/creds" = lib.mkIf config.confSymlinks.configs.jellyfinShim {
        path = "${config.xdg.configHome}/jellyfin-mpv-shim/cred.json";
      };

      ## rofi-bitwarden
      "services/rbw/config" = lib.mkIf config.programs.rbw.enable {
        mode = "0644";
        path = "${config.xdg.configHome}/rbw/config.json";
      };

      # chatgpt
      "services/chatgpt/api_key" = { };
    };
  };
}
