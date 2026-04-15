{
  config,
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
      bitwarden-desktop
      discord
      dracula-theme
      fontconfig
      grimblast
      hyprpolkitagent
      jq
      keyutils
      libnotify
      fastfetch
      rivalcfg
      rofi-rbw-wayland
      signal-desktop
      spice-gtk
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
        build-nix = "nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'";
        cpu_usage = "ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%cpu | head";
        mem_usage = "ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%mem | head";
        shred = "shred -zfu";
        nixos-rebuild = "systemd-inhibit --no-pager --no-legend --mode=block --who='${vars.username}' --why='NixOS Upgrades' sudo nixos-rebuild $@ --option eval-cache false --show-trace";
        spicy = "spicy --spice-ca-file=/etc/pki/libvirt-spice/ca-cert.pem --uri 'spice://127.0.0.1' -p 5900 -s 5901 --title 'th3h4x0r' -f > /dev/null 2>&1 &|";
        pass = "pass -c main";
      };

      history.path = "${config.xdg.dataHome}/zsh/zsh_history";

      initContent = ''
        bindkey -M viins '\e.' insert-last-word
      '';
    };

    git.settings.user.signingKey = "7D73BA8CF10F7F67";
    gpg.scdaemonSettings.disable-ccid = true;
  };

  services.gpg-agent.pinentry.package = pkgs.pinentry-curses;

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
