{
  config,
  lib,
  pkgs,
  pkgs-stable,
  inputs,
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
    homeDirectory = "/Users/${vars.username}";

    sessionVariables = {
    };

    packages = with pkgs; [
      gnupg
    ];
  };

  programs = {
    home-manager = {
      enable = true;
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

    #User shell - START #
    zsh = {
      enable = true;
      autosuggestion = {
        enable = true;
      };
      sessionVariables = {
        GNUMAKEFLAGS = "-j12";
        LESSHISTFILE = "-";
      };
      shellAliases = {
        ll = "ls -lah";
        nixos-rebuild = "sudo darwin-rebuild switch --flake .#macbook";
      };
    };
    # User shell - END #

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };

    git = {
      enable = true;
      signing = {
        key = "AFDFD922BF2CF6EC743FD59B7D73BA8CF10F7F67";
        signByDefault = true;
      };
      settings = {
        user = {
          name = "5ysk3y";
          email = "62815243+5ysk3y@users.noreply.github.com";
        };
        push.autoSetupRemote = "true";
      };
    };

    htop = {
      enable = true;
      package = pkgs.htop-vim;
    };
  };

  ## END PROGAMS

  ## START SERVICES
  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableZshIntegration = true;
      defaultCacheTtl = 600;
      maxCacheTtl = 7200;
      pinentry = {
        package = pkgs.pinentry_mac;
      };
    };
  };
  ## END SERVICES ##

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
  ];
}
