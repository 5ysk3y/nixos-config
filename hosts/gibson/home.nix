{
  config,
  lib,
  pkgs,
  pkgs-stable,
  pkgs-old,
  inputs,
  doomemacs,
  vars,
  hostname,
  ...
}:
{
  home = {
    username = "${vars.username}";
    homeDirectory = "/home/${vars.username}";

    pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 22;
    };

    sessionVariables = {
      NIXOS_OZONE_WL = 1;
      QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";
      GIT_AUTO_FETCH_INTERVAL = 1200;
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
      (inputs.nixos-xivlauncher-rb.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
        useGameMode = true;
      })
      (import ../../home/modules/applications/dim-screen { inherit pkgs; })
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
    qutebrowser = true;
    fuzzel = true;
  };

  ## END CUSTOM MODULES

  programs = with pkgs; {
    home-manager = {
      enable = true;
    };

    #User shell - START #
    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      loginExtra = ''
        start-hyprland && exit
      '';
      autosuggestion = {
        enable = true;
      };
      sessionVariables = {
        GNUMAKEFLAGS = "-j12";
        LESSHISTFILE = "-";
      };
      shellAliases = {
        ls = "ls --color";
        ll = "ls -lash";
        build-nix = "nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'";
        cpu_usage = "ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%cpu | head";
        mem_usage = "ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%mem | head";
        shred = "shred -zfu";
        nixos-rebuild = "systemd-inhibit --no-pager --no-legend --mode=block --who='${vars.username}' --why='NixOS Upgrades' sudo nixos-rebuild --flake ${vars.nixos-config} $@ --option eval-cache false --show-trace";
        spicy = "spicy --spice-ca-file=/etc/pki/libvirt-spice/ca-cert.pem --uri 'spice://127.0.0.1' -p 5900 -s 5901 --title 'th3h4x0r' -f > /dev/null 2>&1 &|";
        pass = "pass -c main";
      };
      oh-my-zsh = {
        enable = true;
        theme = "gentoo";
        plugins = [
          "sudo"
          "git"
          "vi-mode"
          "git-auto-fetch"
        ];
      };
      history = {
        path = "${config.xdg.dataHome}/zsh/zsh_history";
      };
      initContent = ''
        vim() {
          emacsclient -c --no-wait "$@"
        }

        bindkey -M viins '\e.' insert-last-word
      '';
    };
    # User shell - END #

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };

    git = {
      enable = true;
      settings = {
        user = {
          name = "5ysk3y";
          email = "62815243+5ysk3y@users.noreply.github.com";
        };
        alias = {
          newpr = "!git fetch origin -p && git checkout -B wip origin/main";
          st = "!git status";
        };
        push = {
          default = "current";
          autoSetupRemote = "true";
        };
        branch = {
          autoSetupMerge = true;
        };
        commit.gpgsign = true;
        user.signingkey = "7D73BA8CF10F7F67";
      };
      includes = [
        {
          condition = "gitdir:~/nixos-config/**";
          contents = {
            core = {
              hooksPath = ".githooks";
            };
          };
        }
      ];
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
        vo = "dmabuf-wayland";
        hwdec = "vaapi";
        gpu-context = "wayland";
        user-agent = "Mozilla/5.0";
        cache = "yes";
        save-position-on-quit = "yes";
        ytdl-format = "bestvideo+bestaudio";
        stream-buffer-size = "5MiB";
        demuxer-max-bytes = "1G";
        ao = "pipewire";
        volume = 70;
      };
      scripts = [
        mpvScripts.mpris
      ];
    };

    mangohud = {
      enable = true;
    };

    yt-dlp = {
      enable = true;
      settings = {
        cookies-from-browser = "chromium:'~/.local/share/qutebrowser'";
      };
    };

    htop = {
      enable = true;
      package = htop-vim;
    };

    obs-studio = {
      enable = true;
      plugins = [
        pkgs.obs-studio-plugins.obs-vaapi
        pkgs.obs-studio-plugins.obs-pipewire-audio-capture
        pkgs.obs-studio-plugins.obs-scale-to-sound
        pkgs.obs-studio-plugins.obs-vkcapture
        pkgs.obs-studio-plugins.obs-gstreamer
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
      enable = true;
      scdaemonSettings = {
        disable-ccid = true;
      };
    };
  };

  ## END PROGAMS

  ## START SERVICES
  services = {
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
      extraConfig = ''
        pinentry-program ${pkgs.pinentry-curses}/bin/pinentry-curses
      '';
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

  # XDG Spec Handling
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

  # GTK bits.. Cos GNOME.

  gtk = {
    enable = true;
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
    theme = {
      name = "Dracula";
      package = pkgs.dracula-theme;
    };
    iconTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
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

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.

  home.stateVersion = "23.11";

  # Let home Manager install and manage itself.

  imports = [
    ../../home/modules
    inputs.wayland-pipewire-idle-inhibit.homeModules.default
  ];
}
