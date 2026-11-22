{
  config,
  inputs,
  lib,
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

    # Makes qutebrowser the default browser. Its bundle only declares web
    # links through the macbook overlay, so macOS is told to re-read it first.
    # macOS keeps every qutebrowser build it has seen in the store, and sends
    # links to whichever it likes, often an old one. Such a link starts a
    # second qutebrowser, which hands the tab to the running one and leaves
    # its window in the background. So only the current build stays known.
    # defaultbrowser runs only when it isn't the default already, because
    # macOS asks you to confirm each change.
    activation.defaultBrowser = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
      app="${config.programs.qutebrowser.package}/Applications/qutebrowser.app"
      $lsregister -dump \
        | { grep -o '/nix/store/[^ ]*-qutebrowser-[^/ ]*/Applications/qutebrowser\.app' || true; } \
        | sort -u \
        | while read -r old; do
            if [ "$old" != "$app" ]; then
              run $lsregister -u "$old"
            fi
          done
      run $lsregister -f "$app"
      if ! ${lib.getExe pkgs.defaultbrowser} | grep -qx '\* qutebrowser'; then
        run ${lib.getExe pkgs.defaultbrowser} qutebrowser
      fi
    '';
  };

  programs = {
    git = {
      settings = {
        user.signingKey = "D4D5DFADF6AE96D9";
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
