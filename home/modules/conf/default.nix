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
  draculaPath = builtins.toString inputs.qute-dracula.outPath;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
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

    home.file."${config.home.homeDirectory}/.local/share/pass/main.gpg" =
      lib.mkIf (config.confSymlinks.configs.gnupg && isLinux)
        {
          source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/gnupg/main.gpg";
        };

    home.file."${config.xdg.configHome}/OpenRGB/MainBlue.orp" =
      lib.mkIf (config.confSymlinks.configs.openrgb && isLinux)
        {
          source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/OpenRGB/MainBlue.orp";
        };

    home.file."${config.xdg.configHome}/mako/notification.wav" =
      lib.mkIf (config.services.mako.enable && isLinux)
        {
          source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/mako/notification.wav";
        };

    home.file."${config.xdg.configHome}/Wallpapers" =
      lib.mkIf (config.confSymlinks.configs.wallpapers && isLinux)
        {
          source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/Wallpapers";
          recursive = true;
        };

    home.file."${config.xdg.configHome}/obs-studio" =
      lib.mkIf (config.programs.obs-studio.enable && isLinux)
        {
          source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/obs-studio";
          recursive = true;
        };

    home.file."${config.xdg.configHome}/WebCord" =
      lib.mkIf (config.confSymlinks.configs.webcord && isLinux)
        {
          source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/WebCord";
          recursive = true;
        };

    home.file."${config.home.homeDirectory}/.ssh" =
      lib.mkIf (config.confSymlinks.configs.ssh && isLinux)
        {
          source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Private/Keys";
          recursive = true;
        };

    home.file."${quteConfigDir}/dracula" = lib.mkIf config.applications.qutebrowser {
      source = draculaPath;
      recursive = true;
    };

    home.file."${config.xdg.configHome}/rofi/config.rasi" =
      lib.mkIf (config.applications.qutebrowser && isLinux)
        {
          text = builtins.readFile ./files/rofi/config.rasi;
        };

    home.file."${config.xdg.configHome}/OpenRGB/OpenRGB.json" =
      lib.mkIf (config.confSymlinks.configs.openrgb && isLinux)
        {
          text = builtins.readFile ./files/openrgb/openrgb.json;
        };

    home.file."${config.xdg.configHome}/jellyfin-mpv-shim/conf.json" =
      lib.mkIf (config.confSymlinks.configs.jellyfinShim && isLinux)
        {
          text = builtins.readFile ./files/jellyfin-mpv-shim/conf.json;
        };

    home.file."${config.xdg.configHome}/jellyfin-mpv-shim/input.json" =
      lib.mkIf (config.confSymlinks.configs.jellyfinShim && isLinux)
        {
          text = ''
            q run "/bin/sh" "-c" "hyprctl --batch 'dispatch killactive; dispatch workspace m-1'"
          '';
        };

    home.file."${config.xdg.configHome}/jellyfin-mpv-shim/mpv.json" =
      lib.mkIf config.confSymlinks.configs.jellyfinShim
        {
          text = builtins.readFile ./files/jellyfin-mpv-shim/mpv.json;
        };

    home.file."${config.xdg.configHome}/streamdeck-ui/streamdeck_ui.json" =
      lib.mkIf (config.confSymlinks.configs.streamdeckui && isLinux)
        {
          text = builtins.readFile ./files/streamdeck-ui/streamdeck_ui.json;
        };

    home.file."${config.xdg.configHome}/streamdeck-ui/streamdeck_ui.conf" =
      lib.mkIf (config.confSymlinks.configs.streamdeckui && isLinux)
        {
          text = builtins.readFile ./files/streamdeck-ui/streamdeck_ui.conf;
        };
  };
}
