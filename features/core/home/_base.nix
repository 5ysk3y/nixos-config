{
  config,
  lib,
  vars,
  pkgs,
  ...
}:
{
  home = {
    inherit (vars) username homeDirectory;

    packages = with pkgs; [
      bat
    ];

    sessionVariables = {
      GIT_AUTO_FETCH_INTERVAL = 1200;
      NIXOS_CONFIG = vars.configDir;
    };

    stateVersion = "23.11";

    # On the macbook, the Syncthing folder lives in iCloud Drive
    file."Sync" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Sync/";
      recursive = true;
    };
  };

  programs.home-manager.enable = true;
}
