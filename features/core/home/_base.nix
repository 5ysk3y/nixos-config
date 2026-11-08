{
  config,
  lib,
  vars,
  pkgs,
  ...
}:
let
  link = config.lib.file.mkOutOfStoreSymlink;
in
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

    file = {
      # SSH keys and config, kept in Syncthing
      ".ssh" = {
        source = link "${vars.syncthingPath}/Private/Keys";
        recursive = true;
      };

      # On the macbook, the Syncthing folder lives in iCloud Drive
      "Sync" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        source = link "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Sync/";
        recursive = true;
      };
    };
  };

  programs.home-manager.enable = true;
}
