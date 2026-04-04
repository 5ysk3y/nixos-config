{
  config,
  lib,
  pkgs,
  inputs,
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

  features.home.syncthing = {
    enable = true;
    deviceName = "macbook";

    folders.sync = {
      enable = true;
      path = "${vars.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Sync";
      type = "receiveonly";
      peers = [ "syncMaster" ];

      bootstrap.enable = false;
    };
  };
}
