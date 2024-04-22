{ config, lib, pkgs, pkgs-stable, hyprlock, hypridle, inputs, doomemacs, vars, ... }:

let
  secretsPath = builtins.toString inputs.nix-secrets;
in
{
  home = {
    username = "${vars.username}";
    homeDirectory = "/home/${vars.username}";

    activation = {
      setupEtc = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        /run/current-system/sw/bin/systemctl start --user sops-nix
      '';
    };

    pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 22;
    };

    sessionVariables = {
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/Sync/Private/Keys/sops-nix";
      EMAIL = "$(cat ${config.sops.secrets."services/git/email".path} )";
    };

    packages = with pkgs; [
        bat
        bc
        # https://community.bitwarden.com/t/unlock-with-pin-setting-cannot-be-set/64959
        # Pin configuration bug preventing use of pin numbers.
        clipboard-jh
        dracula-theme
        fontconfig
        glib
        grimblast
        hydra-check
        jq
        keyutils
        mpvpaper
        pavucontrol
        pinentry-curses
        pwvucontrol
        qpwgraph
        sops
        spice-gtk
        swww
        vlc
        vulkan-tools
        wayvnc
        webcord
        wl-clipboard
    ];
  };

  ## CUSTOM MODULES

  confSymlinks = {
    enable = true;
    configs = {
      cider = false;
      jellyfinShim = false;
      openrgb = false;
      qpwgraph = false;
      streamdeckui = false;
      webcord = false;
      ssh = true;
    };
  };

  scripts = {
    enable = true;
    waybar = {
      enable = false;
    };
  };

  applications = {
    hypr.enable = true;
    doomemacs = true;
    qutebrowser = true;
    rofi = true;
  };

  ## END CUSTOM MODULES

  programs = {
    home-manager = {
      enable = true;
    };

  #User shell - START #
    zsh = {
      enable = true;
      dotDir = ".config/zsh";
      loginExtra = "Hyprland && exit";
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
  nixos-rebuild = "systemd-inhibit --no-pager --no-legend --mode block --who='${vars.username}' --why='NixOS Upgrades' sudo nixos-rebuild --flake ${vars.nixos-config} $@ --option eval-cache false --show-trace";
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
        ];
      };
      history = {
        path = "${config.xdg.dataHome}/zsh/zsh_history";
      };
      initExtra = ''
vim() {
  emacsclient --create-frame --tty "$@"
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
      userName = "5ysk3y";
      extraConfig = {
        push.autoSetupRemote = "true";
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

    htop = {
      enable = true;
      package = pkgs.htop-vim;
    };

    kitty = {
      enable = true;
      theme = "Dracula";
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
        background_opacity = "0.8";
      };
    };

   gpg = {
     enable = true;
   };
 };

  ## END PROGAMS

  ## START SERVICES
  services = {
    mako = {
      enable = true;
      backgroundColor = "#282A36";
      textColor = "#FFFFFF";
      padding = "10";
      font = "Tamzen 12";
      layer = "overlay";
      anchor = "top-right";
      margin = "11";
      defaultTimeout = 20000;
      borderSize = 1;
      borderRadius = 5;
      width = 400;
      height = 170;
      maxIconSize = 32;
      extraConfig =
"[urgency=low]
border-color=#BD93F9

[urgency=normal]
border-color=#BD93F9
on-notify=exec ${pkgs.vlc}/bin/cvlc --play-and-exit ${config.xdg.configHome}/mako/notification.wav

[urgency=high]
border-color=#FF5555
on-notify=exec ${pkgs.vlc}/bin/cvlc --play-and-exit ${config.xdg.configHome}/mako/notification.wav

[mode=idle]
default-timeout=0
ignore-timeout=1";
    };

   gpg-agent = {
     enable = true;
     extraConfig = "pinentry-program ${pkgs.pinentry-curses}/bin/pinentry-curses";
   };

   gnome-keyring = {
     enable = true;
   };
 };

  ## END SERVICES ##

 # XDG Spec Handling
  xdg = {
    enable = true;
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
  };

  sops = {
    age.keyFile = "${config.home.homeDirectory}/Sync/Private/Keys/sops-nix";
    defaultSopsFile = "${secretsPath}/secrets/secrets.yaml";
    defaultSopsFormat = "yaml";

    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";

    secrets = {
      ## jellyfin
      "services/jellyfin/creds" = lib.mkIf config.confSymlinks.configs.jellyfinShim {
        path = "${config.xdg.configHome}/jellyfin-mpv-shim/cred.json";
      };

      ## git
      "services/git/email" = {};

      ## rofi-bitwarden
      "services/rbw/config" = lib.mkIf config.programs.rbw.enable {
         mode = "0644";
         path = "${config.xdg.configHome}/rbw/config.json";
      };

      # gnupg
      gnupg-BFC2DEE396C3C60124F1DD48D021869A34507FAE = {
        format = "binary";
        sopsFile = "${secretsPath}/secrets/gnupg/BFC2DEE396C3C60124F1DD48D021869A34507FAE.key";
        path = "${config.home.homeDirectory}/.gnupg/private-keys-v1.d/BFC2DEE396C3C60124F1DD48D021869A34507FAE.key";
      };

      # pass
      gnupg-pass = {
        format = "binary";
        sopsFile = "${secretsPath}/secrets/gnupg/main.enc.gpg";
        path = "${config.home.homeDirectory}/.local/share/pass/main.gpg";
      };
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
    ../../modules
    inputs.hyprlock.homeManagerModules.hyprlock
    inputs.hypridle.homeManagerModules.hypridle
  ];
}
