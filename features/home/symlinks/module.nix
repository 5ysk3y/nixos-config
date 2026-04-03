{
  vars,
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  isLinux = pkgs != null && pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs != null && pkgs.stdenv.hostPlatform.isDarwin;
  draculaPath = builtins.toString inputs.qute-dracula.outPath;
in
{
  home.file = {
    ".local/share/pass/main.gpg" = lib.mkIf isLinux {
      source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/gnupg/main.gpg";
    };

    "Sync" = lib.mkIf isDarwin {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Sync/";
      recursive = true;
    };

    ".ssh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Private/Keys";
      recursive = true;
    };

    ".qutebrowser/dracula" = lib.mkIf config.programs.qutebrowser.enable {
      source = draculaPath;
      recursive = true;
    };
  };

  xdg.configFile = {
    "OpenRGB/MainBlue.orp" = lib.mkIf isLinux {
      source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/OpenRGB/MainBlue.orp";
    };

    "mako/notification.wav" = lib.mkIf (config.services.mako.enable && isLinux) {
      source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/mako/notification.wav";
    };

    "Wallpapers" = lib.mkIf isLinux {
      source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/Wallpapers";
      recursive = true;
    };

    "obs-studio" = lib.mkIf (config.programs.obs-studio.enable && isLinux) {
      source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/obs-studio";
      recursive = true;
    };

    "WebCord" = lib.mkIf isLinux {
      source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/WebCord";
      recursive = true;
    };

    "qutebrowser/dracula" = lib.mkIf isLinux {
      source = draculaPath;
      recursive = true;
    };

    "rofi/config.rasi" = lib.mkIf isLinux {
      text = builtins.readFile ./files/rofi/config.rasi;
    };

    "OpenRGB/OpenRGB.json" = lib.mkIf isLinux {
      text = builtins.readFile ./files/openrgb/openrgb.json;
    };

    "jellyfin-mpv-shim/conf.json" = lib.mkIf isLinux {
      text = builtins.readFile ./files/jellyfin-mpv-shim/conf.json;
    };

    "jellyfin-mpv-shim/input.json" = lib.mkIf isLinux {
      text = ''
        q run "/bin/sh" "-c" "hyprctl --batch 'dispatch killactive; dispatch workspace m-1'"
      '';
    };

    "jellyfin-mpv-shim/mpv.conf" = lib.mkIf isLinux {
      text = builtins.readFile ./files/jellyfin-mpv-shim/mpv.conf;
    };

    "streamdeck-ui/streamdeck_ui.json" = lib.mkIf isLinux {
      text = builtins.readFile ./files/streamdeck-ui/streamdeck_ui.json;
    };

    "streamdeck-ui/streamdeck_ui.conf" = lib.mkIf isLinux {
      text = builtins.readFile ./files/streamdeck-ui/streamdeck_ui.conf;
    };
  };
}
