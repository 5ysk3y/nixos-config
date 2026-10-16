{
  pkgs,
  vars,
  ...
}:
{
  home = {
    homeDirectory = "/Users/${vars.username}";

    pointerCursor.enable = false;

    packages = with pkgs; [
      attic-client
      syncthingtray
    ];
  };

  programs = {
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
