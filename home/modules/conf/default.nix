{
  config,
  lib,
  pkgs,
  home-manager,
  inputs,
  vars,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  draculaPath = builtins.toString inputs.qute-dracula.outPath;
  quteConfigDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/.qutebrowser"
    else
      "${config.xdg.configHome}/qutebrowser";
in
{
  options = {
    confSymlinks = {
      enable = lib.mkEnableOption "Enables default smymlinks.";

      configs = {
        gnupg = lib.mkOption { type = lib.types.bool; };
        openrgb = lib.mkOption { type = lib.types.bool; };
        wallpapers = lib.mkOption { type = lib.types.bool; };
        webcord = lib.mkOption { type = lib.types.bool; };
        ssh = lib.mkOption { type = lib.types.bool; };
        streamdeckui = lib.mkOption { type = lib.types.bool; };
        jellyfinShim = lib.mkOption { type = lib.types.bool; };
      };
    };
  };

  config = lib.mkIf config.confSymlinks.enable {

    home = {
      file = {
        "${config.home.homeDirectory}/.local/share/pass/main.gpg" =
          lib.mkIf (config.confSymlinks.configs.gnupg && isLinux)
            {
              source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/gnupg/main.gpg";
            };

        "${config.xdg.configHome}/OpenRGB/MainBlue.orp" =
          lib.mkIf (config.confSymlinks.configs.openrgb && isLinux)
            {
              source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/OpenRGB/MainBlue.orp";
            };

        "${config.xdg.configHome}/mako/notification.wav" =
          lib.mkIf (config.services.mako.enable && isLinux)
            {
              source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/mako/notification.wav";
            };

        "${config.xdg.configHome}/Wallpapers" =
          lib.mkIf (config.confSymlinks.configs.wallpapers && isLinux)
            {
              source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/Wallpapers";
              recursive = true;
            };

        "${config.xdg.configHome}/obs-studio" = lib.mkIf (config.programs.obs-studio.enable && isLinux) {
          source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/obs-studio";
          recursive = true;
        };

        "${config.xdg.configHome}/WebCord" = lib.mkIf (config.confSymlinks.configs.webcord && isLinux) {
          source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/WebCord";
          recursive = true;
        };

        "${config.home.homeDirectory}/.ssh" = lib.mkIf (config.confSymlinks.configs.ssh && isLinux) {
          source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Private/Keys";
          recursive = true;
        };

        "${quteConfigDir}/dracula" = lib.mkIf config.applications.qutebrowser {
          source = draculaPath;
          recursive = true;
        };

        "${config.xdg.configHome}/rofi/config.rasi" =
          lib.mkIf (config.applications.qutebrowser && isLinux)
            {
              text = builtins.readFile ./files/rofi/config.rasi;
            };

        "${config.xdg.configHome}/OpenRGB/OpenRGB.json" =
          lib.mkIf (config.confSymlinks.configs.openrgb && isLinux)
            {
              text = builtins.readFile ./files/openrgb/openrgb.json;
            };

        "${config.xdg.configHome}/jellyfin-mpv-shim/conf.json" =
          lib.mkIf (config.confSymlinks.configs.jellyfinShim && isLinux)
            {
              text = builtins.readFile ./files/jellyfin-mpv-shim/conf.json;
            };

        "${config.xdg.configHome}/jellyfin-mpv-shim/input.json" =
          lib.mkIf (config.confSymlinks.configs.jellyfinShim && isLinux)
            {
              text = ''
                q run "/bin/sh" "-c" "hyprctl --batch 'dispatch killactive; dispatch workspace m-1'"
              '';
            };

        "${config.xdg.configHome}/jellyfin-mpv-shim/mpv.json" =
          lib.mkIf config.confSymlinks.configs.jellyfinShim
            {
              text = builtins.readFile ./files/jellyfin-mpv-shim/mpv.json;
            };

        "${config.xdg.configHome}/streamdeck-ui/streamdeck_ui.json" =
          lib.mkIf (config.confSymlinks.configs.streamdeckui && isLinux)
            {
              text = builtins.readFile ./files/streamdeck-ui/streamdeck-ui.json;
            };

        "${config.xdg.configHome}/streamdeck-ui/streamdeck_ui.conf" =
          lib.mkIf (config.confSymlinks.configs.streamdeckui && isLinux)
            {
              text = builtins.readFile ./files/streamdeck-ui/streamdeck_ui.conf;
            };
      };
    };
  };
}
