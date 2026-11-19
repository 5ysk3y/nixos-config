{
  inputs,
  pkgs,
  vars,
  ...
}:
{
  imports = with inputs.self.modules.homeManager; [
    attic-client
    wireshark
  ];

  home = {
    pointerCursor.enable = false;

    packages = with pkgs; [
      arp-scan
      bfg-repo-cleaner
      e2fsprogs
      nmap
      restic
      socat
      syncthingtray
      utm
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
