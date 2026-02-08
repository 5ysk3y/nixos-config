{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
{
  home = {
    homeDirectory = "/Users/${vars.username}";

    sessionVariables = {
    };

    packages = with pkgs; [
      nixfmt
    ];
  };

  confSymlinks = {
    enable = true;
  };

  ## START PROGAMS

  programs = {
    zsh = {
      shellAliases = {
        ll = "ls -lah";
        nixos-rebuild = "sudo darwin-rebuild switch --flake .#macbook";
      };
    };

    git = {
      settings = {
        user.signingKey = "D4D5DFADF6AE96D9";
      };
    };
  };

  ## END PROGAMS
  ## START SERVICES

  services = {
    gpg-agent = {
      pinentry = {
        package = pkgs.pinentry_mac;
      };
    };
  };

  ## END SERVICES ##
}
