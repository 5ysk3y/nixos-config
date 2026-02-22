{
  config,
  lib,
  pkgs,
  vars,
  ...
}:

let
  ghKey = pkgs.fetchurl {
    url = "https://github.com/5ysk3y.gpg";
    sha256 = "1w6vml01gf81mnck4gmwi91ynkhwdsw8z84lxjlz8bvbwrj6cwrx";
  };
in

{
  home = {
    username = "${vars.username}";

    sessionVariables = {
      GIT_AUTO_FETCH_INTERVAL = 1200;
      NIXOS_CONFIG = "${config.home.homeDirectory}/nixos-config";
    };

    packages = with pkgs; [
      nixfmt
    ];

    stateVersion = "23.11";
  };

  programs = with pkgs; {
    home-manager = {
      enable = true;
    };

    zsh = {
      enable = true;
      autosuggestion = {
        enable = true;
      };
      sessionVariables = {
        GNUMAKEFLAGS = "-j12";
        LESSHISTFILE = "-";
      };
      initContent = ''
        vim() {
          emacsclient -c --tty "$@"
        }
      '';
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
    };

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
          newpr = "!f() { git fetch origin -p && git checkout -B \"$1\" origin/main && git branch --unset-upstream; }; f";
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

    gpg = {
      enable = true;
      publicKeys = [
        {
          source = ghKey;
          trust = 5;
        }
      ];
    };

    htop = {
      enable = true;
      package = htop-vim;
    };

    yt-dlp = {
      enable = true;
    };
  };

  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableZshIntegration = true;
      defaultCacheTtl = 600;
      maxCacheTtl = 7200;
    };
  };
}
