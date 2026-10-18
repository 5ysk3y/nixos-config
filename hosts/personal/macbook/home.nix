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

  launchd.agents.syncthingtray = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.syncthingtray}/Applications/syncthingtray.app/Contents/MacOS/syncthingtray"
      ];
      RunAtLoad = true;
      # Restart on crash, but let "Quit" from the tray menu actually quit.
      KeepAlive.SuccessfulExit = false;
      ProcessType = "Interactive";
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
