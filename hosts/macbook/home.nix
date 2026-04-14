{
  config,
  lib,
  pkgs,
  inputs,
  vars,
  hostname,
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

  programs = {
    zsh = {
      shellAliases = {
        nixos-rebuild = "sudo darwin-rebuild switch --flake .#macbook";
      };
    };

    git = {
      settings = {
        user.signingKey = "D4D5DFADF6AE96D9";
      };
    };

    qutebrowser.extraConfig = ''
      c.fonts.default_size = "12pt"
    '';
  };

  services = {
    gpg-agent = {
      pinentry = {
        package = pkgs.pinentry_mac;
      };
    };
  };

  features = {
    home = {
      syncthing = {
        enable = true;
        deviceName = "${hostname}";

        folders.sync = {
          enable = true;
          path = vars.syncthingPath;
          type = "receiveonly";
          peers = [ "syncMaster" ];
        };
      };
    };
  };
}
