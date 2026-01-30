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
      mpv
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
