{
  config,
  lib,
  inputs,
  vars,
  hostname,
  pkgs,
  ...
}:
{
  home = {
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
    };

    packages = with pkgs; [
      act
      bat
      bitwarden-desktop
      bottles
      discord
      dracula-theme
      fontconfig
      glib
      grimblast
      heroic
      hyprpolkitagent
      (inputs.nixos-xivlauncher-rb.packages.${stdenv.hostPlatform.system}.default.override {
        useGameMode = true;
      })
      jellyfin-desktop
      jellyfin-mpv-shim
      jq
      keyutils
      krita
      libnotify
      mpvpaper
      nixfmt
      nixd
      fastfetch
      obs-cmd
      pavucontrol
      playerctl
      protonup-qt
      pwvucontrol
      restic
      rivalcfg
      rofi-rbw-wayland
      signal-desktop
      sops
      spice-gtk
      vlc
      vulkan-tools
      webcord
      wl-clipboard
      wtype
    ];
  };

  programs = {
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
        nixos-rebuild = "systemd-inhibit --no-pager --no-legend --mode=block --who='${vars.username}' --why='NixOS Upgrades' sudo nixos-rebuild $@ --option eval-cache false --show-trace";
        spicy = "spicy --spice-ca-file=/etc/pki/libvirt-spice/ca-cert.pem --uri 'spice://127.0.0.1' -p 5900 -s 5901 --title 'th3h4x0r' -f > /dev/null 2>&1 &|";
        pass = "pass -c main";
        less = "bat $@";
      };

      history.path = "${config.xdg.dataHome}/zsh/zsh_history";

      initContent = ''
        bindkey -M viins '\e.' insert-last-word
      '';
    };

    git.settings.user.signingKey = "7D73BA8CF10F7F67";

    gpg.scdaemonSettings = {
      disable-ccid = true;
    };
  };

  services.gpg-agent = {
    pinentry = {
      package = pkgs.pinentry-curses;
    };
  };

  features = {
    home = {
      mako = {
        output = "DP-1";
      };
      syncthing = {
        enable = true;
        deviceName = "${hostname}";

        folders.sync = {
          enable = true;
          path = vars.syncthingPath;
          type = "sendreceive";
          peers = [ "syncMaster" ];

          bootstrap = {
            enable = true;
          };
        };
      };
    };
  };
}
